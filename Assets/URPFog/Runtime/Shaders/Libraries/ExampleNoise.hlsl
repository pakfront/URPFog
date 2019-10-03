// MIT License

// Copyright (c) 2018 Michael Woodard

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

//---------------------------------------------------------------------------------------------------------
// Math Functions
//---------------------------------------------------------------------------------------------------------
float3 interpolationC2(float3 x){ return x*x*x*(x*(x*6.0 - 15.0) + 10.0);}

float setRange(float value, float low, float high){ return saturate((value-low)/(high-low)); }

float3 setRangesSigned(float3 values, float low, float high){ return (values-low)/(high-low);}

float dilatePerlinWorley(float p, float w, float x){
	float curve = 0.75;
	if(x < 0.5){
		x /= 0.5;
		float n = p + w * x;
		return n * lerp(1, 0.5, pow(x,curve));
	}
	else{
		x = (x-0.5)/0.5;
		float n = w + p *(1.0 - x);
		return n * lerp(0.5, 1.0, pow(x, 1.0/curve));
	}
}


//---------------------------------------------------------------------------------------------------------
// Perlin Noise
//---------------------------------------------------------------------------------------------------------
void perlinHash(float3 gridcell, float s, bool tile,
				out float4 lowzHash0, out float4 lowzHash1, out float4 lowzHash2,
				out float4 highzHash0, out float4 highzHash1, out float4 highzHash2 )
{
	const float2 OFFSET = float2( 50.0, 161.0 );
	const float DOMAIN = 69.0;
	const float3 SOMELARGEFLOATS = float3(635.298681, 682.357502, 668.926525);
	const float3 ZINC = float3(48.500388, 65.294118, 63.934599);

	gridcell.xyz =  gridcell.xyz - floor(gridcell.xyz * (1.0 / DOMAIN)) * DOMAIN;
	float d = DOMAIN - 1.5;
	float3 gridcellInc1 = step(gridcell, float3(d,d,d)) * (gridcell + 1.0);

	gridcellInc1 = tile ? gridcellInc1 % s : gridcellInc1;

	float4 p = float4(gridcell.xy, gridcellInc1.xy) + OFFSET.xyxy;
	p *= p;
	p = p.xzxz * p.yyww;
	float3 lowzMod = float3(1.0 / (SOMELARGEFLOATS.xyz + gridcell.zzz * ZINC.xyz));
	float3 highzMod = float3(1.0 / (SOMELARGEFLOATS.xyz + gridcellInc1.zzz * ZINC.xyz));
	lowzHash0 = frac(p*lowzMod.xxxx);
	highzHash0 = frac(p*highzMod.xxxx);
	lowzHash1 = frac(p*lowzMod.yyyy);
	highzHash1 = frac(p*highzMod.yyyy);
	lowzHash2 = frac(p*lowzMod.zzzz);
	highzHash2 = frac(p*highzMod.zzzz);
}

float perlin(float3 p, float s, bool tile){
	p *= s;

	float3 pI = floor(p);
	float3 pI2 = floor(p);
	float3 pF = p - pI;
	float3 pFMin1 = pF - 1.0;

	float4 hashx0, hashy0, hashz0, hashx1, hashy1, hashz1;
	perlinHash(pI2, s, tile, hashx0, hashy0, hashz0, hashx1, hashy1, hashz1);

	float4 gradx0 = hashx0 - 0.49999;
	float4 grady0 = hashy0 - 0.49999;
	float4 gradz0 = hashz0 - 0.49999;
	float4 gradx1 = hashx1 - 0.49999;
	float4 grady1 = hashy1 - 0.49999;
	float4 gradz1 = hashz1 - 0.49999;
	float4 gradResults0 = rsqrt(gradx0 * gradx0 + grady0 * grady0 + gradz0 * gradz0) * (float2(pF.x, pFMin1.x).xyxy * gradx0 + float2(pF.y, pFMin1.y).xxyy * grady0 + pF.zzzz * gradz0);
	float4 gradResults1 = rsqrt(gradx1 * gradx1 + grady1 * grady1 + gradz1 * gradz1) * (float2(pF.x, pFMin1.x).xyxy * gradx1 + float2(pF.y, pFMin1.y).xxyy * grady1 + pFMin1.zzzz * gradz1);

	float3 blend = interpolationC2(pF);
	float4 res0 = lerp(gradResults0, gradResults1, blend.z);
	float4 blend2 = float4(blend.xy, float2(1.0 - blend.xy));
	float final = dot(res0, blend2.zxzx * blend2.wwyy);
	final *= 1.0/sqrt(0.75);
	return ((final * 1.5) + 1.0) * 0.5;
}

float perlin(float3 p){
	return perlin(p, 1, false);
}

float perlin5(float3 p, bool tile){
	float3 xyz = p;
	float amplitudeFactor = 0.5;
	float frequencyFactor = 2.0;

	float a = 1.0;
	float val = 0.0;
	val += a * perlin(xyz).r; a *= amplitudeFactor; xyz *= (frequencyFactor + 0.02);
	val += a * perlin(xyz).r; a *= amplitudeFactor; xyz *= (frequencyFactor + 0.03);
	val += a * perlin(xyz).r; a *= amplitudeFactor; xyz *= (frequencyFactor + 0.01);
	val += a * perlin(xyz).r; a *= amplitudeFactor; xyz *= (frequencyFactor + 0.01);
	val += a * perlin(xyz).r;

	return val;
}

float perlin7(float3 p, float s){
	float3 xyz = p;
	float f = 1.0;
	float a = 1.0;

	float val = 0.0;
	val += a * perlin(xyz, s*f, true).r; a *= 0.5; f*= 2.0;
	val += a * perlin(xyz, s*f, true).r; a *= 0.5; f*= 2.0;
	val += a * perlin(xyz, s*f, true).r; a *= 0.5; f*= 2.0;
	val += a * perlin(xyz, s*f, true).r; a *= 0.5; f*= 2.0;
	val += a * perlin(xyz, s*f, true).r; a *= 0.5; f*= 2.0;
	val += a * perlin(xyz, s*f, true).r; a *= 0.5; f*= 2.0;
	val += a * perlin(xyz, s*f, true).r; a *= 0.5; f*= 2.0;

	return val;
}


//---------------------------------------------------------------------------------------------------------
// Curl Noise
//---------------------------------------------------------------------------------------------------------
float3 encodeCurl(float3 c){
	return (c + 1.0) * 0.5;
}

float3 curlNoise(float3 p){
	float e = 0.05;
	float n1, n2, a, b;
	float3 c;

	n1 = perlin5(p.xyz + float3(0,e,0), true);
	n2 = perlin5(p.xyz + float3(0,-e,0), true);
	a = (n1-n2)/(2*e);
	n1 = perlin5(p.xyz + float3(0,0,e), true);
	n2 = perlin5(p.xyz + float3(0,0,-e), true);
	b = (n1-n2)/(2*e);

	c.x = a - b;

	n1 = perlin5(p.xyz + float3(0,0,e), true);
	n2 = perlin5(p.xyz + float3(0,0,-e), true);
	a = (n1-n2)/(2*e);
	n1 = perlin5(p.xyz + float3(e,0,0), true);
	n2 = perlin5(p.xyz + float3(-e,0,0), true);
	b = (n1-n2)/(2*e);

	c.y = a - b;

	n1 = perlin5(p.xyz + float3(e,0,0), true);
	n2 = perlin5(p.xyz + float3(-e,0,0), true);
	a = (n1-n2)/(2*e);
	n1 = perlin5(p.xyz + float3(0,e,0), true);
	n2 = perlin5(p.xyz + float3(0,-e,0), true);
	b = (n1-n2)/(2*e);

	c.z = a - b;

	return c;
}

//---------------------------------------------------------------------------------------------------------
// Cellular Noise
//---------------------------------------------------------------------------------------------------------
float3 voronoi_hash(float3 x, float s){
	x = x % s;
	x = float3(dot(x, float3(127.1, 311.7, 74.7)),
				dot(x, float3(269.5,183.3,246.1)),
				dot(x, float3(113.5,271.9,124.6)));
	return frac(sin(x) * 43758.5453123);
}

float3 voronoi( in float3 x, float s, bool inverted){
	x *= s;
	x += 0.5;
	float3 p = floor(x);
	float3 f = frac(x);

	float id = 0.0;
	float2 res = float2(1.0, 1.0);
	for(int k = -1; k <= 1; k++){
		for(int j = -1; j <= 1; j++){
			for(int i = -1; i <= 1; i++){
				float3 b = float3(i,j,k);
				float3 r = float3(b) - f + voronoi_hash(p+b, s);
				float d = dot(r,r);

				if(d < res.x){
					id = dot(p+b, float3(1.0, 57.0, 113.0));
					res = float2(d, res.x);
				}
				else if(d < res.y){
					res.y = d;
				}
			}
		}
	}
	float2 result = res;
	id = abs(id);
	if(inverted)
		return float3(1.0 - result, id);
	else
		return float3(result, id);
}

float worley3(float3 p, float s){
	float3 xyz = p;

	float val1 = voronoi(xyz, 1.0 * s, true).r;
	float val2 = voronoi(xyz, 2.0 * s, false).r;
	float val3 = voronoi(xyz, 4.0 * s, false).r;

	val1 = saturate(val1);
	val2 = saturate(val2);
	val3 = saturate(val3);

	float worleyVal = val1;
	worleyVal = worleyVal - val2 * 0.3;
	worleyVal = worleyVal - val3 * 0.3;

	return worleyVal;	
}
