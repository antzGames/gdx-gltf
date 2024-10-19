#ifdef shadowMapFlag
	uniform float u_shadowBias;
	uniform sampler2D u_shadowTexture;
	uniform float u_shadowPCFOffset;
	varying vec3 v_shadowMapUv;
	// Antz: ivec3(pcfCount, pcfDither, normalBiasInverse)
	uniform ivec3 u_advancedShadowsConfig;

highp float random(vec2 co) {
	highp float a = 12.9898;
	highp float b = 78.233;
	highp float c = 43758.5453;
	highp float dt = dot(co.xy, vec2(a, b));
	highp float sn = mod(dt, 3.14);
	return fract(sin(sn) * c);
}

#ifdef numCSM

// arrays of samplers don't seem to work well with ANGLE/DXD11 on Windows so use invididual uniforms instead
uniform sampler2D u_csmSamplers0;
uniform sampler2D u_csmSamplers1;
uniform sampler2D u_csmSamplers2;
uniform sampler2D u_csmSamplers3;
uniform sampler2D u_csmSamplers4;
uniform sampler2D u_csmSamplers5;
uniform sampler2D u_csmSamplers6;
uniform sampler2D u_csmSamplers7;
uniform vec2 u_csmPCFClip[numCSM];
varying vec3 v_csmUVs[numCSM];



		float getCSMShadowness(sampler2D sampler, vec3 uv, vec2 offset, vec3 normal_bias) {
			offset += vec2(normal_bias.x, normal_bias.y);
			const vec4 bitShifts = vec4(1.0, 1.0 / 255.0, 1.0 / 65025.0, 1.0 / 16581375.0);
			return step(uv.z + normal_bias.z, dot(texture2D(sampler, uv.xy + offset), bitShifts) + u_shadowBias); // (1.0/255.0)
		}

		float getCSMShadow(sampler2D sampler, vec3 uv, float pcf, vec3 normalBias, int isDither, int pcfCount){

			// Calculate dither if set
			vec2 dither = vec2(0.0);
			if (isDither == 1){
				// Note: sin hash function needs big seeds (numbers) for best results
				float rand = random(uv.xy / pcf);
				//dither = vec2(rand,rand) * 2.0 * u_shadowPCFOffset;  // fast but squarish
				dither = vec2(sqrt(rand)*cos(6.28318 * rand), sqrt(rand)*sin(6.28318 * rand)) * 2.0 * pcf; // rounder dither
			}

			if (pcfCount == 1) {
				return (
					getCSMShadowness(sampler, uv, vec2(pcf, pcf) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(-pcf, pcf) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(pcf, -pcf) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(-pcf, -pcf) + dither, normalBias)) * 0.25;
			} else if (pcfCount == 2) {

				/*-------------
				      x
			        x   x
			      x       x
			        x   x
			          x
			    ------------- */

				return(
					getCSMShadowness(sampler, uv, vec2(pcf, pcf) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(-pcf, pcf) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(pcf, -pcf) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(-pcf, -pcf) + dither, normalBias) +

					getCSMShadowness(sampler, uv, vec2(0.0, pcf*2.0) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(-pcf*2.0, 0.0) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(0.0, -pcf*2.0) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(pcf*2.0, 0.0) + dither, normalBias)) * 0.125;
			} else if (pcfCount == 3) {

				/*------------
				      x
				   x     x
				      x
			    x   x   x   x
			          x
			       x     x
			          x
			    ------------- */

				return(
					getCSMShadowness(sampler, uv, vec2(0.0, pcf) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(-pcf, 0.0) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(0.0, -pcf) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(-pcf, -pcf) + dither, normalBias) +

					getCSMShadowness(sampler, uv, vec2(pcf, pcf) * 2.0 + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(-pcf, pcf) * 2.0 + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(pcf, -pcf) * 2.0 + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(-pcf, -pcf) * 2.0 + dither, normalBias) +

					getCSMShadowness(sampler, uv, vec2(0.0, pcf * 3.0) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(-pcf * 3.0, 0.0) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(0.0, -pcf * 3.0) + dither, normalBias) +
					getCSMShadowness(sampler, uv, vec2(pcf * 3.0, 0.0) + dither, normalBias)) / 12.0;
			}
		}

		float getShadow() {
			// get values from u_advancedShadowsConfig uniform
			int pcfCount = u_advancedShadowsConfig.x; // PCF 1 == gdx-gltf default, 2 == 8 samples, 3 == 12 samples
			int isDither = u_advancedShadowsConfig.y; // 0 == default gdx-gltf, 1 == fast sin hash
			int normalBiasInverse = u_advancedShadowsConfig.z; // 0 == no normal bias

			// set default values to zero
			vec3 normal_bias = vec3(0.0);

			for(int i=0 ; i<numCSM ; i++){
				vec2 pcfClip = u_csmPCFClip[i];
				float pcf = pcfClip.x;
				float clip = pcfClip.y;
				vec3 uv = v_csmUVs[i];
				if(uv.x >= clip && uv.x <= 1.0 - clip &&
					uv.y >= clip && uv.y <= 1.0 - clip &&
					uv.z >= 0.0 && uv.z <= 1.0){

					// if normal bias is not 0 then scale the normal bias variable
					if (normalBiasInverse != 0) {
						normal_bias = getNormal() * (1.0 / float(normalBiasInverse));
					}

					#if numCSM > 0
					if(i == 0) return getCSMShadow(u_csmSamplers0, uv, pcf, normal_bias, isDither, pcfCount);
					#endif
					#if numCSM > 1
					if(i == 1) return getCSMShadow(u_csmSamplers1, uv, pcf, normal_bias, isDither, pcfCount);
					#endif
					#if numCSM > 2
					if(i == 2) return getCSMShadow(u_csmSamplers2, uv, pcf, normal_bias, isDither, pcfCount);
					#endif
					#if numCSM > 3
					if(i == 3) return getCSMShadow(u_csmSamplers3, uv, pcf, normal_bias, isDither, pcfCount);
					#endif
					#if numCSM > 4
					if(i == 4) return getCSMShadow(u_csmSamplers4, uv, pcf, normal_bias, isDither, pcfCount);
					#endif
					#if numCSM > 5
					if(i == 5) return getCSMShadow(u_csmSamplers5, uv, pcf, normal_bias, isDither, pcfCount);
					#endif
					#if numCSM > 6
					if(i == 6) return getCSMShadow(u_csmSamplers6, uv, pcf, normal_bias, isDither, pcfCount);
					#endif
					#if numCSM > 7
					if(i == 7) return getCSMShadow(u_csmSamplers7, uv, pcf, normal_bias, isDither, pcfCount);
					#endif
				}
			}
			// default map
			return getCSMShadow(u_shadowTexture, v_shadowMapUv, u_shadowPCFOffset, normal_bias, isDither, pcfCount);
		}

	#else

		float getShadowness(vec2 offset, vec3 normal_bias) {
			offset += vec2(normal_bias.x, normal_bias.y);
			const vec4 bitShifts = vec4(1.0, 1.0 / 255.0, 1.0 / 65025.0, 1.0 / 16581375.0);
			return step(v_shadowMapUv.z + normal_bias.z, dot(texture2D(u_shadowTexture, v_shadowMapUv.xy + offset), bitShifts) + u_shadowBias); // (1.0/255.0)
		}

		float getShadow() {
			// get values from u_advancedShadowsConfig uniform
			int pcfCount = u_advancedShadowsConfig.x; // PCF 1 == gdx-gltf default, 2 == 8 samples, 3 == 12 samples
			int isDither = u_advancedShadowsConfig.y; // 0 == default gdx-gltf, 1 == fast sin hash
			int normalBiasInverse = u_advancedShadowsConfig.z; // 0 == no normal bias

			// set default values to zero
			float total = 0.0;
			vec2 dither = vec2(0.0);
			vec3 normal_bias = vec3(0.0);

			// if normal bias is not 0 then scale the normal bias variable
			if (normalBiasInverse != 0) {
				normal_bias = getNormal() * (1.0 / float(normalBiasInverse));
			}

			// Calculate dither if set
			if (isDither == 1){
				// Note: sin hash function needs big seeds (numbers) for best results
				float rand = random(v_shadowMapUv.xy / u_shadowPCFOffset);
				//dither = vec2(rand,rand) * 2.0 * u_shadowPCFOffset;  // fast but squarish
				dither = vec2(sqrt(rand)*cos(6.28318 * rand), sqrt(rand)*sin(6.28318 * rand)) * 2.0 * u_shadowPCFOffset; // rounder dither
			}

			// PCF (1x1) is basically the original default for gdx-gltf
			if (pcfCount == 1){

			    /*----------
			        x  x
                    x  x
			    ----------- */

				total =
					getShadowness(vec2(u_shadowPCFOffset, u_shadowPCFOffset) + dither, normal_bias) +
					getShadowness(vec2(-u_shadowPCFOffset, u_shadowPCFOffset) + dither, normal_bias) +
					getShadowness(vec2(u_shadowPCFOffset, -u_shadowPCFOffset) + dither, normal_bias) +
					getShadowness(vec2(-u_shadowPCFOffset, -u_shadowPCFOffset) + dither, normal_bias);
				total /= 4.0;

			} else if (pcfCount == 2) {

				/*-----------
				      x
			        x   x
			      x       x
			        x   x
			          x
			    ------------- */

				total =
					getShadowness(vec2(u_shadowPCFOffset, u_shadowPCFOffset) + dither, normal_bias) +
					getShadowness(vec2(-u_shadowPCFOffset, u_shadowPCFOffset) + dither, normal_bias) +
					getShadowness(vec2(u_shadowPCFOffset, -u_shadowPCFOffset) + dither, normal_bias) +
					getShadowness(vec2(-u_shadowPCFOffset, -u_shadowPCFOffset) + dither, normal_bias) +

					getShadowness(vec2(0.0, u_shadowPCFOffset * 2.0) + dither, normal_bias) +
					getShadowness(vec2(-u_shadowPCFOffset * 2.0, 0.0) + dither, normal_bias) +
					getShadowness(vec2(0.0, -u_shadowPCFOffset * 2.0) + dither, normal_bias) +
					getShadowness(vec2(u_shadowPCFOffset * 2.0, 0.0) + dither, normal_bias);
				total /= 8.0;

			} else if (pcfCount == 3) {

				/*------------
				      x
				   x     x
				      x
			    x   x   x   x
			          x
			       x     x
			          x
			    ------------- */

				total =
					getShadowness(vec2(0.0, u_shadowPCFOffset) + dither, normal_bias) +
					getShadowness(vec2(-u_shadowPCFOffset, 0.0) + dither, normal_bias) +
					getShadowness(vec2(0.0, -u_shadowPCFOffset ) + dither, normal_bias) +
					getShadowness(vec2(u_shadowPCFOffset, 0.0) + dither, normal_bias) +

					getShadowness(vec2(u_shadowPCFOffset, u_shadowPCFOffset) * 2.0 + dither, normal_bias) +
					getShadowness(vec2(-u_shadowPCFOffset, u_shadowPCFOffset) * 2.0 + dither, normal_bias) +
					getShadowness(vec2(u_shadowPCFOffset, -u_shadowPCFOffset) * 2.0 + dither, normal_bias) +
					getShadowness(vec2(-u_shadowPCFOffset, -u_shadowPCFOffset) * 2.0 + dither, normal_bias) +

					getShadowness(vec2(0.0, u_shadowPCFOffset * 3.0) + dither, normal_bias) +
					getShadowness(vec2(-u_shadowPCFOffset * 3.0, 0.0) + dither, normal_bias) +
					getShadowness(vec2(0.0, -u_shadowPCFOffset * 3.0) + dither, normal_bias) +
					getShadowness(vec2(u_shadowPCFOffset * 3.0, 0.0) + dither, normal_bias);
				total /= 12.0;
			}

			return total;
		}

	#endif
#endif //shadowMapFlag
