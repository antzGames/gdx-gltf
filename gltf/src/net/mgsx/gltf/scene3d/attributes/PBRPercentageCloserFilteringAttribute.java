package net.mgsx.gltf.scene3d.attributes;

import com.badlogic.gdx.graphics.g3d.Attribute;

public class PBRPercentageCloserFilteringAttribute extends Attribute
{
	public final static String PcfConfigAlias = "PcfConfig";
	public final static long PcfConfig = register(PcfConfigAlias);

	public int pcf = 1, dither = 0;

	public PBRPercentageCloserFilteringAttribute(long type, int pcf, int dither) {
		super(type);
		this.pcf = pcf;
		this.dither = dither;
	}
	
	@Override
	public Attribute copy() {
		return new PBRPercentageCloserFilteringAttribute(type, pcf, dither);
	}

	@Override
	public int compareTo(Attribute attribute) {
		if (type != attribute.type) return (int)(type - attribute.type);

		int i = Integer.compare(this.pcf, ((PBRPercentageCloserFilteringAttribute)attribute).pcf);
		if (i != 0) return i;

		i = Integer.compare(this.dither, ((PBRPercentageCloserFilteringAttribute)attribute).dither);
		return i;
	}
}
