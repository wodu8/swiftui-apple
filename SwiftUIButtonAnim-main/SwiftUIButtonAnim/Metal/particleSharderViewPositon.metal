//


#include <metal_stdlib>
#include "particleSharder.h"

using namespace metal;

// ViewPostionを持つ方式
struct RasterizerData {
  float4 position [[position]];
  float size [[point_size]];
  float4 color;
};



kernel void particleViewPositionCompute(device Particle* particles [[buffer(0)]],
                            device Particle* outParticles [[buffer(1)]],
                                                        constant vector_float2 *viewportSizePointer [[buffer(2)]],
                            uint index [[thread_position_in_grid]])
{
//  vector_float2 position =  particles[index].position + particles[index].velocity;

  Particle particle = particles[index];
  vector_float2 velocity = particle.velocity;
  vector_float2 position = particle.position + velocity;

  if (position.x >= (*viewportSizePointer).x / 2 || position.x <= -(*viewportSizePointer).x / 2 ||
      position.y >= (*viewportSizePointer).y / 2 || position.y <= -(*viewportSizePointer).y / 2) {
      position = vector_float2(0.0f, 0.0f);
  }

  outParticles[index].position = position;
  float4 color = particle.color * 0.99;
  if (color.x <= 0.1) {
      color.x = 1.0;
  }
  if (color.y <= 0.1) {
      color.y = 1.0;
  }
//  if (color.z <= 0.1) {
//      color.z = 1.0;
//  }
  if (color.w <= 0.1) {
      color.w = 1.0;
  }
//      outParticles[index].position = position;
      outParticles[index].velocity = velocity;
      outParticles[index].color = color;
}


vertex RasterizerData particleViewPositionVertex(unsigned int particleID [[vertex_id]],
                               const device Particle *particles [[buffer(0)]],
                                     constant vector_float2 *viewportSizePointer [[buffer(1)]]){
  RasterizerData out;

//  vector_float2 viewportSizeHalf = *viewportSizePointer / 2.0;
//  out.position.xy = particles[particleID].position / viewportSizeHalf;

//  vector_float2 viewportSizeHalf = *viewportSizePointer / 2.0;
  out.position.xy = particles[particleID].position / 500;



      out.size = 1.0f;
      out.color = particles[particleID].color;

      return out;
}

fragment float4 particleViewPositionFragment(Particle particle [[stage_in]]) {
    return (float4)particle.color;
}
