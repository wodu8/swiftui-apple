//

#include <metal_stdlib>

#include "particleSharder.h"

using namespace metal;

// ViewPostionを持つ方式
struct RasterizerData
{
  float4 position [[position]];
  float size [[point_size]];
  float4 color;
};

// 乱数生成のためのヘルパー関数
float random(float2 seed) {
    return fract(sin(dot(seed, float2(12.9898,78.233))) * 43758.5453);
//  return seed.x / 100000;
}

// 乱数を使用して色を生成するサンプル関数
float4 generateRandomColor(float2 seed) {
//    return float4(random(seed), random(seed + 0.5), random(seed + 1.0), 1.0);
  float r = random(seed);
  float g = random(seed + 1.0);
  float b = random(seed + 2.0);
  float a = 1.0;
  
  return float4(r, g, b, a );
}

// 乱数を使用して速度を生成するサンプル関数
float2 generateRandomVelocity(float2 seed) {
  return float2(random(seed) - 0.5, random(seed + 0.5) - 0.5) * 0.01;
}

float2 generateRandomPosition(float2 seed) {
    return float2(random(seed) - 0.5, random(seed + 0.5) - 0.5) * 2.0;
//  return seed;
}

//


//uint xorShift32(device uint* state) {
//    *state ^= (*state << 13);
//    *state ^= (*state >> 17);
//    *state ^= (*state << 5);
//    return *state;
//}
//
//float xorShift32( uint state) {
//    state ^= (state << 13);
//    state ^= (state >> 17);
//    state ^= (state << 5);
//    return float(state) / float(UINT_MAX);
//}

//

uint xorshift32(thread uint* state) {
    *state ^= (*state << 13);
    *state ^= (*state >> 17);
    *state ^= (*state << 5);
    return *state;
}

float randXORShift(thread uint* state) {
    return float(xorshift32(state)) / 4294967295.0;
}


kernel void particleMetalPositionMake(device Particle *particles [[buffer(0)]],
                                      constant uint *states [[buffer(1)]],
//                                      device ParticleDebug *debug [[buffer(2)]],
                                      uint2 index [[thread_position_in_grid]])
{
//  float2 seed = float2(*states + index ,*states + index );
  float findex = float(index.x) + 1.0;
  float fnum = float(*states) + 1.0;
//  float fnum = 0.0;
  float2 seed = float2( findex + fnum ,findex + fnum + 1.0);
//  float2 seed = float(index) + 190;
//  uint seed = *states + index.x;
  thread uint32_t state =  *states + index.x;
  uint32_t x = xorshift32(&state);
  
  uint32_t y = xorshift32(&state);

//  debug[index.x].index = index;
//  debug[index.x].states = *states;
//  debug[index.x].rand1 = random(float2(1,1));
//  debug[index.x].rand2 = randXORShift(&state);
//  debug[index.x].rand3 = xorshift32(&state);
//  debug[index.x].rand4 = xorshift32(&state);
//  debug[index.x].rand5 = xorshift32(&state);
//  debug[index.x].rand6 = xorshift32(&state);



  float fx = randXORShift(&state);
  float fy = randXORShift(&state);
  float vx = randXORShift(&state);
  float vy = randXORShift(&state);

//  particles[index].position = generateRandomPosition(seed );
//  uint x =  xorShift32(seed);
  
  
  particles[index.x].position = float2( (fx - 0.5) * 2.0 ,
                                      (fy - 0.5) * 2.0  );

  
//  particles[index].position = float2(index / (*states) * 1.0,index * 0.00001);
//  particles[index].position = float2( (findex / fnum) * 2.0 - 1.0,(findex / fnum) * 2.0 - 1.0);
//  particles[index].position = float2( 0.0,0.0);
  
//  particles[index].velocity = generateRandomVelocity(seed + 1.0);
//  particles[index].color = generateRandomColor(seed + 2.0);
  particles[index.x].color = float4(randXORShift(&state), randXORShift(&state),randXORShift(&state), 1);
  particles[index.x].velocity = float2((vx - 0.5) * 0.01 ,(vy - 0.5) * 0.01 );

}

kernel void particleMetalPositionCompute(device Particle *particles [[buffer(0)]],
                                         device Particle *outParticles [[buffer(1)]],
                                         uint index [[thread_position_in_grid]])
{
  //  vector_float2 position =  particles[index].position +
  //  particles[index].velocity;

  Particle particle = particles[index];
  vector_float2 position = particle.position + particle.velocity;
  vector_float4 color = particle.color;

  if (position.x >= 1.0 || position.x <= -1.0 || 
      position.y >= 1.0 ||      position.y <= -1.0)
  {
    position = vector_float2(0.0f, 0.0f);
  }

  outParticles[index].position = position;
  color *= 0.999;
  if (color.x <= 0.1)
  {
    color.x = 1.0;
  }
  if (color.y <= 0.1)
  {
    color.y = 1.0;
  }
  if (color.z <= 0.01) {
      color.z = 1.0;
  }
  if (color.w <= 0.1)
  {
    color.w = 1.0;
  }
  outParticles[index].color = color;
  outParticles[index].velocity = particle.velocity;
 
}

vertex RasterizerData
particleMetalPositionVertex(unsigned int particleID [[vertex_id]],
                            const device Particle *particles [[buffer(0)]],
                            constant vector_float2 *viewportSizePointer [[buffer(1)]],
                            constant float *particleSize [[buffer(2)]]
                            
                            )
{
  
  RasterizerData out;
  out.position = float4(particles[particleID].position, 0.0, 1.0);

  out.size = *particleSize;
  out.color = particles[particleID].color;

  return out;
}

fragment float4 particleMetalPositionFragment(Particle particle [[stage_in]])
{
  return (float4)particle.color;
}
