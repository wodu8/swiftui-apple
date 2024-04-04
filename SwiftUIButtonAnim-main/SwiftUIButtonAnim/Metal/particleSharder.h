

#ifndef PARTICLESHARDER_H
#define PARTICLESHARDER_H

#include <simd/simd.h>

typedef struct Particle {
    vector_float2 position;
    vector_float2 velocity;
    vector_float4 color;
} Particle;

typedef struct ParticleDebug {
  vector_uint2 index;
  uint states;
  float rand1;
  float rand2;
  uint rand3;
  uint rand4;
  uint rand5;
  uint rand6;
} ParticleDebug;
#endif /* PARTICLESHARDER_H */
 
