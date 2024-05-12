package net.mgsx.gltf.scene3d.attributes;

import com.badlogic.gdx.graphics.g3d.Attribute;

public class PBRShadowsAttribute extends Attribute
{
	public final static String PcfConfigAlias = "PcfConfig";
	public final static long PcfConfig = register(PcfConfigAlias);

	public int pcf = 1, dither = 0;

	public PBRShadowsAttribute(long type, int pcf, int dither) {
		super(type);
		this.pcf = pcf;
		this.dither = dither;
	}
	
	@Override
	public Attribute copy() {
		return new PBRShadowsAttribute(type, pcf, dither);
	}

	@Override
	public int compareTo(Attribute attribute) {
		if (type != attribute.type) return (int)(type - attribute.type);

		int i = Integer.compare(this.pcf, ((PBRShadowsAttribute)attribute).pcf);
		if (i != 0) return i;

		i = Integer.compare(this.dither, ((PBRShadowsAttribute)attribute).dither);
		return i;
	}
}
