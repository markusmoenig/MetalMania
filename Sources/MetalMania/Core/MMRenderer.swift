//
//  Renderer.swift
//  Framework
//
//  Created by Markus Moenig on 01.01.19.
//  Copyright © 2019 Markus Moenig. All rights reserved.
//

import Foundation

import Metal
import MetalKit

public class MMRenderer : NSObject, MTKViewDelegate {
    
    let device          : MTLDevice
    let commandQueue    : MTLCommandQueue
    
    var renderPipelineState : MTLRenderPipelineState!

    var outputTexture   : MTLTexture!
    
    var viewportSize    : vector_uint2
    
    let pipelineStateDescriptor : MTLRenderPipelineDescriptor
    var renderEncoder   : MTLRenderCommandEncoder!
    
    var defaultLibrary  : MTLLibrary! = nil
    
    let mmView          : MMView
    var vertexBuffer    : MTLBuffer?
    
    var width           : Float!
    var height          : Float!
    
    var cWidth          : Float!
    var cHeight         : Float!
    
    var clipRects       : [MMRect] = []
    
    var currentRenderEncoder: MTLRenderCommandEncoder?
    
    init?( _ view: MMView ) {
        mmView = view
        device = mmView.device!
        
        // --- Size
        viewportSize = vector_uint2( UInt32(mmView.bounds.width), UInt32(mmView.bounds.height) )
        viewportSize.x *= UInt32(mmView.scaleFactor)
        viewportSize.y *= UInt32(mmView.scaleFactor)
        width = Float( viewportSize.x ); height = Float( viewportSize.y );
        cWidth = Float( viewportSize.x ) / mmView.scaleFactor; cHeight = Float( viewportSize.y ) / mmView.scaleFactor
        
        defaultLibrary = try? device.makeLibrary(source: MMRenderer.getMetalLibrary(), options: nil)// device.makeDefaultLibrary()!
        mmView.colorPixelFormat = MTLPixelFormat.bgra8Unorm;//_srgb;

        let vertexFunction = defaultLibrary.makeFunction( name: "mmQuadVertexShader" )
//        let fragmentFunction = defaultLibrary.makeFunction( name: "mmQuadSamplingShader" )

        pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexFunction
//        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mmView.colorPixelFormat;
        
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
    
        commandQueue = device.makeCommandQueue()!
        super.init()

        allocateTextures()
    }
    
    func createNewPipelineState( _ fragmentFunction: MTLFunction ) -> MTLRenderPipelineState?
    {
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        do {
            let renderPipelineState = try device.makeRenderPipelineState( descriptor: pipelineStateDescriptor )
            return renderPipelineState
        } catch {
            print( "createNewPipelineState failed" )
            return nil
        }
    }
    
    func encodeStart( view: MTKView, commandBuffer: MTLCommandBuffer ) -> MTLRenderCommandEncoder?
    {
        let renderPassDescriptor = view.currentRenderPassDescriptor
        
        renderPassDescriptor!.colorAttachments[0].loadAction = .clear
        renderPassDescriptor!.colorAttachments[0].clearColor = MTLClearColor( red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        if ( renderPassDescriptor != nil )
        {
            renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor! )
            renderEncoder?.label = "MyRenderEncoder";
            
            renderEncoder?.setViewport( MTLViewport( originX: 0.0, originY: 0.0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: -1.0, zfar: 1.0 ) )
            
            renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder?.setVertexBytes( &viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
            
//            renderEncoder?.setFragmentTexture(outputTexture, index: 0)
            
            return renderEncoder
        }
        
        return nil
    }
    
    func encodeRun( _ renderEncoder: MTLRenderCommandEncoder, pipelineState: MTLRenderPipelineState? )
    {
        renderEncoder.setRenderPipelineState( pipelineState! )
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    func encodeEnd( _ renderEncoder: MTLRenderCommandEncoder )
    {
        renderEncoder.endEncoding()
    }
    
    func setClipRect(_ rect: MMRect? = nil )
    {
        func applyClipRect(_ rect: MMRect)
        {
            let x : Int = Int(rect.x * mmView.scaleFactor)
            let y : Int = Int(rect.y * mmView.scaleFactor)
            
            var width : Int = Int(rect.width * mmView.scaleFactor)
            var height : Int = Int(rect.height * mmView.scaleFactor )
            
            if x + width < 0 {
                return;
            }
            
            if x > Int(self.width) {
                return;
            }
            
            if y + height < 0 {
                return
            }
            
            if y > Int(self.height) {
                return;
            }
            
            if x + width > Int(self.width) {
                width -= x + width - Int(self.width)
            }
            
            if y + height > Int(self.height) {
                height -= y + height - Int(self.height)
            }
            
            currentRenderEncoder?.setScissorRect( MTLScissorRect(x: x, y: y, width: width, height: height ) )
        }
        
        if rect != nil {
            
            let newRect = MMRect(rect!)

            if clipRects.count > 0 {
                newRect.intersect( clipRects[clipRects.count-1] )
            }
            
            applyClipRect(newRect)
            clipRects.append(newRect)
        } else {
            if clipRects.count > 0 {
                clipRects.removeLast()
            }
            
            if clipRects.count > 0 {
                //let last = clipRects.removeLast()
                applyClipRect( clipRects[clipRects.count-1] )
            } else {
                currentRenderEncoder?.setScissorRect( MTLScissorRect(x:0, y:0, width:Int(viewportSize.x), height:Int(viewportSize.y) ) )
            }
        }
    }
    
    public func draw(in view: MTKView)
    {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = encodeStart( view: view, commandBuffer: commandBuffer )
        
        currentRenderEncoder = renderEncoder
        mmView.build()
        encodeEnd( renderEncoder! )
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
    
    func allocateTextures() {
        
        outputTexture = nil
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D;
        textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm;
        textureDescriptor.width = Int(viewportSize.x);
        textureDescriptor.height = Int(viewportSize.y);
        textureDescriptor.usage = MTLTextureUsage.shaderRead;
        
        textureDescriptor.usage = MTLTextureUsage.unknown;
        outputTexture = device.makeTexture( descriptor: textureDescriptor )
        
        // Setup the vertex buffer
        vertexBuffer = createVertexBuffer( MMRect( 0, 0, width, height ) )
    }
    
    /// Creates a vertex MTLBuffer for the given rectangle
    func createVertexBuffer(_ rect: MMRect ) -> MTLBuffer?
    {
        let left = -self.width / 2 + rect.x
        let right = left + rect.width//self.width / 2 - x
        
        let top = self.height / 2 - rect.y
        let bottom = top - rect.height

        let quadVertices: [Float] = [
            right, bottom, 1.0, 0.0,
            left, bottom, 0.0, 0.0,
            left, top, 0.0, 1.0,
            
            right, bottom, 1.0, 0.0,
            left, top, 0.0, 1.0,
            right, top, 1.0, 1.0,
        ]
        
        return device.makeBuffer(bytes: quadVertices, length: quadVertices.count * MemoryLayout<Float>.stride, options: [])!
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
        viewportSize.x = UInt32( size.width )
        viewportSize.y = UInt32( size.height )
        
        width = Float( size.width )
        height = Float( size.height )
        
        cWidth = width / mmView.scaleFactor
        cHeight = height / mmView.scaleFactor
                
        allocateTextures()
        
        /// Notify the regions
        if let region = mmView.leftRegion {
            region.resize(width: width, height: height)
        }
        if let region = mmView.topRegion {
            region.resize(width: width, height: height)
        }
        if let region = mmView.rightRegion {
            region.resize(width: width, height: height)
        }
        if let region = mmView.bottomRegion {
            region.resize(width: width, height: height)
        }
        if let region = mmView.editorRegion {
            region.resize(width: width, height: height)
        }
    }
    
    static func getMetalLibrary() -> String {
        return """

        #include <metal_stdlib>
        #include <simd/simd.h>
        using namespace metal;

        //#import "../ShaderTypes.h"

        typedef struct
        {
            vector_float2 position;
            vector_float2 textureCoordinate;
        } MM_Vertex;

        typedef struct
        {
            vector_float4 fillColor;
            vector_float4 borderColor;
            float radius, borderSize;
        } MM_SPHERE;

        typedef struct
        {
            float2 size;
            float2 sp, ep;
            float width, borderSize;
            float4 fillColor;
            float4 borderColor;
            
        } MM_LINE;

        typedef struct
        {
            float2 size;
            float2 sp, cp, ep;
            float width, borderSize;
            float fill1, fill2;
            float4 fillColor;
            float4 borderColor;
            
        } MM_SPLINE;

        typedef struct
        {
            vector_float2 size;
            float round, borderSize;
            vector_float4 fillColor;
            vector_float4 borderColor;

        } MM_BOX;

        typedef struct
        {
            vector_float2 size;
            float round, borderSize;
            vector_float4 fillColor;
            vector_float4 borderColor;
            float4 rotation;

        } MM_ROTATEDBOX;

        typedef struct
        {
            vector_float2 size;
            float round, borderSize;
            vector_float4 fillColor;
            vector_float4 borderColor;
            
        } MM_BOXEDMENU;

        typedef struct
        {
            vector_float2 size;
            float round, borderSize;
            vector_float2 uv1;
            vector_float2 uv2;
            vector_float4 gradientColor1;
            vector_float4 gradientColor2;
            vector_float4 borderColor;
            
        } MM_BOX_GRADIENT;

        typedef struct
        {
            float2 screenSize;
            float2 pos;
            float2 size;
            float4 subRect;

        } MM_TEXTURE;

        typedef struct
        {
            float2 atlasSize;
            float2 fontPos;
            float2 fontSize;
            float4 color;
        } MM_TEXT;

        typedef struct
        {
            float2 size;
            float4 color;
            
        } MM_COLORWHEEL;

        typedef struct
        {
            float2 sc;
            float2 r;
            float4 color;
            
        } MM_ARC;

        typedef struct
        {
            float4 clipSpacePosition [[position]];
            float2 textureCoordinate;
        } RasterizerData;

        // Quad Vertex Function
        vertex RasterizerData
        mmQuadVertexShader(uint vertexID [[ vertex_id ]],
                     constant MM_Vertex *vertexArray [[ buffer(0) ]],
                     constant vector_uint2 *viewportSizePointer  [[ buffer(1) ]])

        {
            
            RasterizerData out;
            
            float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
            float2 viewportSize = float2(*viewportSizePointer);
            
            out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
            out.clipSpacePosition.z = 0.0;
            out.clipSpacePosition.w = 1.0;
            
            out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
            return out;
        }

        // --- SDF utilities

        float mmFillMask(float dist)
        {
            return clamp(-dist, 0.0, 1.0);
        }

        float mmBorderMask(float dist, float width)
        {
            return clamp(dist + width, 0.0, 1.0) - clamp(dist, 0.0, 1.0);
        }

        float2 mmRotateCW(float2 pos, float angle)
        {
            float ca = cos(angle), sa = sin(angle);
            return pos * float2x2(ca, -sa, sa, ca);
        }

        // --- Sphere Drawable
        fragment float4 mmSphereDrawable(RasterizerData in [[stage_in]],
                                       constant MM_SPHERE *data [[ buffer(0) ]] )
        {
            float2 uv = in.textureCoordinate * float2( data->radius * 2 + data->borderSize, data->radius * 2 + data->borderSize );
            uv -= float2( data->radius + data->borderSize / 2 );
            
            float dist = length( uv ) - data->radius;
            
            float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, mmFillMask( dist ) * data->fillColor.w );
            col = mix( col, data->borderColor, mmBorderMask( dist, data->borderSize ) );
            return col;
        }

        float mmGradient_linear(float2 uv, float2 p1, float2 p2) {
            return clamp(dot(uv-p1,p2-p1)/dot(p2-p1,p2-p1),0.,1.);
        }

        fragment float4 mmLineDrawable(RasterizerData in [[stage_in]],
                                       constant MM_LINE *data [[ buffer(0) ]] )
        {
            float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
            uv -= float2( data->size / 2.0 + data->borderSize / 2.0 );
        //    uv -= (data->sp + data->ep) / 2;

            float2 o = uv - data->sp;
            float2 l = data->ep - data->sp;
            
            float h = clamp( dot(o,l)/dot(l,l), 0.0, 1.0 );
            float dist = -(data->width-distance(o,l*h));
            
            float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, mmFillMask( dist ) * data->fillColor.w );
            col = mix( col, data->borderColor, mmBorderMask( dist, data->borderSize ) );
            
            return col;
        }

        float mmBezier(float2 pos, float2 p0, float2 p1, float2 p2)
        {
            // p(t)    = (1-t)^2*p0 + 2(1-t)t*p1 + t^2*p2
            // p'(t)   = 2*t*(p0-2*p1+p2) + 2*(p1-p0)
            // p'(0)   = 2(p1-p0)
            // p'(1)   = 2(p2-p1)
            // p'(1/2) = 2(p2-p0)
            float2 a = p1 - p0;
            float2 b = p0 - 2.0*p1 + p2;
            float2 c = p0 - pos;
            
            float kk = 1.0 / dot(b,b);
            float kx = kk * dot(a,b);
            float ky = kk * (2.0*dot(a,a)+dot(c,b)) / 3.0;
            float kz = kk * dot(c,a);
            
            float2 res;
            
            float p = ky - kx*kx;
            float p3 = p*p*p;
            float q = kx*(2.0*kx*kx - 3.0*ky) + kz;
            float h = q*q + 4.0*p3;
            
            if(h >= 0.0)
            {
                h = sqrt(h);
                float2 x = (float2(h, -h) - q) / 2.0;
                float2 uv = sign(x)*pow(abs(x), float2(1.0/3.0));
                float t = uv.x + uv.y - kx;
                t = clamp( t, 0.0, 1.0 );
                
                // 1 root
                float2 qos = c + (2.0*a + b*t)*t;
                res = float2( length(qos),t);
            } else {
                float z = sqrt(-p);
                float v = acos( q/(p*z*2.0) ) / 3.0;
                float m = cos(v);
                float n = sin(v)*1.732050808;
                float3 t = float3(m + m, -n - m, n - m) * z - kx;
                t = clamp( t, 0.0, 1.0 );
                
                // 3 roots
                float2 qos = c + (2.0*a + b*t.x)*t.x;
                float dis = dot(qos,qos);
                
                res = float2(dis,t.x);
                
                qos = c + (2.0*a + b*t.y)*t.y;
                dis = dot(qos,qos);
                if( dis<res.x ) res = float2(dis,t.y );
                
                qos = c + (2.0*a + b*t.z)*t.z;
                dis = dot(qos,qos);
                if( dis<res.x ) res = float2(dis,t.z );
                
                res.x = sqrt( res.x );
            }
            return res.x;
        }

        fragment float4 mmSplineDrawable(RasterizerData in [[stage_in]],
                                        constant MM_SPLINE *data [[ buffer(0) ]] )
        {
            float2 size = data->size;// - float2(400, 400);
            float2 uv = in.textureCoordinate * ( size + float2( data->borderSize ) * 2.0 );
            uv -= float2( size / 2.0 + data->borderSize / 2.0 );
            //    uv -= (data->sp + data->ep) / 2;
            
            float dist = mmBezier( uv, data->sp, data->cp, data->ep ) - data->width;
            
        //    float2 o = uv - data->sp;
        //    float2 l = data->ep - data->sp;
            
        //    float h = clamp( dot(o,l)/dot(l,l), 0.0, 1.0 );
        //    float dist = -(data->width-distance(o,l*h));
            
            float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, mmFillMask( dist ) * data->fillColor.w );
            col = mix( col, data->borderColor, mmBorderMask( dist, data->borderSize ) );
            
            return col;
        }

        // --- Box Drawable
        fragment float4 mmBoxDrawable(RasterizerData in [[stage_in]],
                                       constant MM_BOX *data [[ buffer(0) ]] )
        {
            float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
            uv -= float2( data->size / 2.0 + data->borderSize );

            float2 d = abs( uv ) - data->size / 2 + data->round;
            float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
            
            float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, mmFillMask( dist ) * data->fillColor.w );
            col = mix( col, data->borderColor, mmBorderMask( dist, data->borderSize ) );
            return col;
        }

        fragment float4 mmRotatedBoxDrawable(RasterizerData in [[stage_in]],
                                       constant MM_ROTATEDBOX *data [[ buffer(0) ]] )
        {
            float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
            uv -= float2( data->size / 2.0 + data->borderSize );

            uv = mmRotateCW(uv, data->rotation.x * 3.14159265359 / 180.);
            
            float2 d = abs( uv ) - data->size / 2 + data->round;
            float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
            
            float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, mmFillMask( dist ) * data->fillColor.w );
            col = mix( col, data->borderColor, mmBorderMask( dist, data->borderSize ) );
            return col;
        }

        // --- Box Drawable
        fragment float4 mmBoxPatternDrawable(RasterizerData in [[stage_in]],
                                       constant MM_BOX *data [[ buffer(0) ]] )
        {
            float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
            uv -= float2( data->size / 2.0 + data->borderSize );
            
            float2 d = abs( uv ) - data->size / 2 + data->round;
            float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
            
            float4 checkerColor1 = data->fillColor;
            float4 checkerColor2 = data->borderColor;
            
            //uv = fragCoord;
            uv -= float2( data->size / 2 );
            
            float4 col = checkerColor1;
            
            float cWidth = 24.0;
            float cHeight = 24.0;
            
            if ( fmod( floor( uv.x / cWidth ), 2.0 ) == 0.0 ) {
                if ( fmod( floor( uv.y / cHeight ), 2.0 ) != 0.0 ) col=checkerColor2;
            } else {
                if ( fmod( floor( uv.y / cHeight ), 2.0 ) == 0.0 ) col=checkerColor2;
            }
            
            return float4( col.xyz, mmFillMask( dist ) );
        }

        // --- Box Gradient
        fragment float4 mmBoxGradientDrawable(RasterizerData in [[stage_in]],
                                               constant MM_BOX_GRADIENT *data [[ buffer(0) ]] )
        {
            float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0);
            uv -= float2( data->size / 2.0 + data->borderSize / 2.0 );
            
            float2 d = abs( uv ) - data->size / 2 + data->round;
            float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
            
            uv = in.textureCoordinate;
            uv.y = 1 - uv.y;
            float s = mmGradient_linear( uv, data->uv1, data->uv2 ) / 1;
            s = clamp(s, 0.0, 1.0);
            float4 col = float4( mix( data->gradientColor1.rgb, data->gradientColor2.rgb, s ), mmFillMask( dist ) );
            col = mix( col, data->borderColor, mmBorderMask( dist, data->borderSize ) );
            
            return col;
        }

        // --- Box Drawable
        fragment float4 mmBoxedMenuDrawable(RasterizerData in [[stage_in]],
                                             constant MM_BOXEDMENU *data [[ buffer(0) ]] )
        {
            float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
            uv -= float2( data->size / 2.0 + data->borderSize / 2.0 );
            
            // Main
            float2 d = abs( uv ) - data->size / 2 + data->round;
            float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
            
            float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, mmFillMask( dist ) * data->fillColor.w );
            col = mix( col, data->borderColor, mmBorderMask( dist, data->borderSize ) );
            
            // --- Lines
            
            float lineWidth = 1.5;
            float lineRound = 4.0;
            
            //const float4 lineColor = float4(0.957, 0.957, 0.957, 1.000);
            const float4 lineColor = float4(0.95, 0.95, 0.95, 1.000);

            // --- Middle
            uv = in.textureCoordinate * data->size;
            uv -= data->size / 2.0;

            d = abs( uv ) -  float2( data->size.x / 3, lineWidth) + lineRound;
            dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - lineRound;
            
        //    col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, mmFillMask( dist ) * data->fillColor.w );
            col = mix( col, lineColor, mmFillMask( dist ) );

            // --- Top
            uv = in.textureCoordinate * data->size;
            uv -= data->size / 2.0;
            uv.y -= data->size.y / 4;
            
            d = abs( uv ) -  float2( data->size.x / 3, lineWidth) + lineRound;
            dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - lineRound;
            col = mix( col, lineColor, mmFillMask( dist ) );
            
            // --- Bottom
            uv = in.textureCoordinate * data->size;
            uv -= data->size / 2.0;
            uv.y += data->size.y / 4;
            
            d = abs( uv ) -  float2( data->size.x / 3, lineWidth) + lineRound;
            dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - lineRound;
            col = mix( col, lineColor, mmFillMask( dist ) );
            
            return col;
        }

        // --- Boxed Plus Drawable
        fragment float4 mmBoxedPlusDrawable(RasterizerData in [[stage_in]],
                                              constant MM_BOXEDMENU *data [[ buffer(0) ]] )
        {
            float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
            uv -= float2( data->size / 2.0 + data->borderSize / 2.0 );
            
            // Main
            float2 d = abs( uv ) - data->size / 2 + data->round;
            float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
            
            float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, mmFillMask( dist ) * data->fillColor.w );
            col = mix( col, data->borderColor, mmBorderMask( dist, data->borderSize ) );
            
            // --- Lines
            
            float lineWidth = 2.5;
            float lineRound = 4.0;
            
            // --- Middle
            uv = in.textureCoordinate * data->size;
            uv -= data->size / 2.0;
            
            d = abs( uv ) -  float2( data->size.x / 3, lineWidth) + lineRound;
            dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - lineRound;
            col = mix( col,  float4( 0.957, 0.957, 0.957, 1 ), mmFillMask( dist ) );
            
            d = abs( uv ) -  float2(lineWidth, data->size.y / 3) + lineRound;
            dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - lineRound;
            col = mix( col,  float4( 0.957, 0.957, 0.957, 1 ), mmFillMask( dist ) );
            
            return col;
        }

        // --- Boxed Minus Drawable
        fragment float4 mmBoxedMinusDrawable(RasterizerData in [[stage_in]],
                                             constant MM_BOXEDMENU *data [[ buffer(0) ]] )
        {
            float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
            uv -= float2( data->size / 2.0 + data->borderSize / 2.0 );
            
            // Main
            float2 d = abs( uv ) - data->size / 2 + data->round;
            float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
            
            float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, mmFillMask( dist ) * data->fillColor.w );
            col = mix( col, data->borderColor, mmBorderMask( dist, data->borderSize ) );
            
            // --- Lines
            
            float lineWidth = 2.5;
            float lineRound = 4.0;
            
            // --- Middle
            uv = in.textureCoordinate * data->size;
            uv -= data->size / 2.0;
            
            d = abs( uv ) -  float2( data->size.x / 3, lineWidth) + lineRound;
            dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - lineRound;
            col = mix( col,  float4( 0.957, 0.957, 0.957, 1 ), mmFillMask( dist ) );
            
            return col;
        }

        /// Texture drawable
        fragment float4 mmTextureDrawable(RasterizerData in [[stage_in]],
                                        constant MM_TEXTURE *data [[ buffer(0) ]],
                                        texture2d<half> inTexture [[ texture(1) ]])
        {
            constexpr sampler textureSampler (mag_filter::linear,
                                              min_filter::linear);
            
            float2 uv = in.textureCoordinate;// * data->screenSize;
            uv.y = 1 - uv.y;
            
            uv *= data->subRect.zw;
            uv += data->subRect.xy;

            const half4 colorSample = inTexture.sample (textureSampler, uv );
                
            return float4( colorSample );
        }

        float mmMedian(float r, float g, float b) {
            return max(min(r, g), min(max(r, g), b));
        }

        /// Draw a text char
        fragment float4 mmTextDrawable(RasterizerData in [[stage_in]],
                                        constant MM_TEXT *data [[ buffer(0) ]],
                                        texture2d<half> inTexture [[ texture(1) ]])
        {
            constexpr sampler textureSampler (mag_filter::linear,
                                              min_filter::linear);
            
            float2 uv = in.textureCoordinate;
            uv.y = 1 - uv.y;

            uv /= data->atlasSize / data->fontSize;
            uv += data->fontPos / data->atlasSize;

            const half4 colorSample = inTexture.sample (textureSampler, uv );
            
            float4 sample = float4( colorSample );
            
            float d = mmMedian(sample.r, sample.g, sample.b) - 0.5;
            float w = clamp(d/fwidth(d) + 0.5, 0.0, 1.0);
            return float4( data->color.x, data->color.y, data->color.z, w * data->color.w );
        }


        #define M_PI 3.1415926535897932384626433832795

        float3 getHueColor(float2 pos)
        {
            float theta = 3.0 + 3.0 * atan2(pos.x, pos.y) / M_PI;
            
        //    float3 color = float3(0.0);
            return clamp(abs(fmod(theta + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
        }

        float2 hsl2xy(float3 hsl)
        {
            float h = hsl.r;
            float s = hsl.g;
            float l = hsl.b;
            float theta = 0;
            
            if(h==0.0){
                if(s==1.0){
                    theta = 4.0-l;
                } else {
                    theta = 2.0+s;
                }
            }else if(h==1.0){
                if(s==0.0){
                    theta = l;
                } else {
                    theta = 6.0-s;
                }
            }else{
                if(s==0.0){
                    theta = 2.0-h;
                } else {
                    theta = 4.0+h;
                }
            }
            
            theta = M_PI/6 * theta;
            return float2(cos(theta), sin(theta));
        }

        float3 rgb2hsl( float3 col )
        {
            const float eps = 0.0000001;

            float minc = min( col.r, min(col.g, col.b) );
            float maxc = max( col.r, max(col.g, col.b) );
            float3  mask = step(col.grr,col.rgb) * step(col.bbg,col.rgb);
            float3 h = mask * (float3(0.0,2.0,4.0) + (col.gbr-col.brg)/(maxc-minc + eps)) / 6.0;
            return float3( fract( 1.0 + h.x + h.y + h.z ),              // H
                        (maxc-minc)/(1.0-abs(minc+maxc-1.0) + eps),  // S
                        (minc+maxc)*0.5 );                           // L
        }

        // --- ColorWheel Drawable
        fragment float4 mmColorWheelDrawable(RasterizerData in [[stage_in]],
                                       constant MM_COLORWHEEL *data [[ buffer(0) ]] )
        {
            float2 uv = float2(2.0, -2.0) * (in.textureCoordinate * data->size - 0.5 * data->size) / data->size.y;

            float l = length(uv);

            l = 1.0 - abs((l - 0.875) * 8.0);
            l = clamp(l * data->size.y * 0.0625, 0.0, 1.0);
            
            float4 col = float4(l * getHueColor(uv), l);
            
            if (l < 0.75)
            {
                uv = uv / 0.75;
                
                float3 inhsl = data->color.xyz;//rgb2hsl(data->color.xyz);
                inhsl.x /= 360;

                float angle = ((inhsl.x * 360) - 180) * M_PI / 180;
                float2 mouse = float2( sin(angle), cos(angle) );

                float3 pickedHueColor = getHueColor(mouse);

                mouse = normalize(mouse);
                
                float sat = 1.5 - (dot(uv, mouse) + 0.5); // [0.0,1.5]
                
                if (sat < 1.5)
                {
                    float h = sat / sqrt(3.0);
                    float2 om = cross(float3(mouse, 0.0), float3(0.0, 0.0, 1.0)).xy;

                    float lum = dot(uv, om);
                    
                    if (abs(lum) <= h)
                    {
                        l = clamp((h - abs(lum)) * data->size.y * 0.5, 0.0, 1.0) * clamp((1.5 - sat) / 1.5 * data->size.y * 0.5, 0.0, 1.0); // Fake antialiasing
                        col = float4(l * mix(pickedHueColor, float3(0.5 * (lum + h) / h), sat / 1.5), l);
                    }
                }
                
                //col.xyz = pickedHueColor;
            }
            
            col.w *= data->color.w;

            return col;
        }

        fragment float4 mmArcDrawable(RasterizerData in [[stage_in]],
                                              constant MM_ARC *data [[ buffer(0) ]] )
        {
            float ra = data->r.x;
            float rb = data->r.y;
            
            float2 p = in.textureCoordinate * (ra+rb) * 2;
            p -= float2(ra + rb);
            
            float2 sca = float2(sin(data->sc.x), cos(data->sc.x));
            float2 scb = float2(sin(data->sc.y), cos(data->sc.y));

            p *= float2x2(sca.x,sca.y,-sca.y,sca.x);
            p.x = abs(p.x);
            float k = (scb.y*p.x>scb.x*p.y) ? dot(p.xy,scb) : length(p.xy);
            float dist = sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
            
            float4 col = float4( data->color.x, data->color.y, data->color.z, mmFillMask( dist ) );
            return col;
        }

        """
    }
}
