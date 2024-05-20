package net.mgsx.gltf.scene3d.attributes;

import com.badlogic.gdx.graphics.g3d.Attribute;

public class PBRAdvancedShadowsAttribute extends Attribute
{
	public final static String AdvanceShadowsAlias = "AdvancedShadowsConfig";
	public final static long AdvancedShadowsConfig = register(AdvanceShadowsAlias);

	public int pcf = 1, dither = 0, normalBiasInv = 0;

	public PBRAdvancedShadowsAttribute(long type, int pcf, int dither, int normalBiasInv) {
		super(type);
		this.pcf = pcf;
		this.dither = dither;
		this.normalBiasInv = normalBiasInv;
	}
	
	@Override
	public Attribute copy() {
		return new PBRAdvancedShadowsAttribute(type, pcf, dither, normalBiasInv);
	}

	@Override
	public int compareTo(Attribute attribute) {
		if (type != attribute.type) return (int)(type - attribute.type);

		int i = Integer.compare(this.pcf, ((PBRAdvancedShadowsAttribute)attribute).pcf);
		if (i != 0) return i;

		i = Integer.compare(this.dither, ((PBRAdvancedShadowsAttribute)attribute).dither);
		if (i != 0) return i;

		i = Integer.compare(this.normalBiasInv, ((PBRAdvancedShadowsAttribute)attribute).normalBiasInv);
		return i;
	}
}
