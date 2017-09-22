<!--
	Global parameters and imports expected to be useful to every stylesheet.

	Authors:
	  Maxwell Terpstra <terpstra@alumni.uvic.ca>
-->
<xsl:stylesheet
	version="2.0"
	xmlns:util="http://ise3.uvic.ca/ns/ise2-import/util"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

	<xsl:import href="util.xsl"/>
	<xsl:import href="metadata.xsl"/>

	<xsl:param name="site">ise</xsl:param>
	<xsl:param name="metadataPath">../ise2/metadata</xsl:param>
	<xsl:param name="personographyPath">../ise3/personography.xml</xsl:param>
	<xsl:param name="orgographyPath">../ise3/orgography.xml</xsl:param>
	<xsl:param name="taxonomiesPath">../ise3/taxonomies.xml</xsl:param>

	<xsl:variable name="siteOrgRef" select="
		concat('org:', util:pad(upper-case($site), 4, '-'), '1')
	"/>
	<xsl:variable name="personography" select="doc($personographyPath)"/>
	<xsl:variable name="orgography" select="doc($orgographyPath)"/>
	<xsl:variable name="taxonomies" select="doc($taxonomiesPath)"/>

</xsl:stylesheet>
