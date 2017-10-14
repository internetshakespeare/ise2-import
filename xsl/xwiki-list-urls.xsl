<!--
	Creates a list of document URLs to download from XWiki

	Expects an ISE2 collection metadata document as input

	Authors:
		Maxwell Terpstra <terpstra@alumni.uvic.ca>
-->
<xsl:stylesheet version="2.0"
	xmlns:m="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/text"
	xmlns:meta="http://ise3.uvic.ca/ns/ise2-import/metadata"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	exclude-result-prefixes="#all"
>
	<xsl:import href="global.xsl"/>
	<xsl:param name="xwikiBaseUrl"/>

	<xsl:output method="text"/>

	<xsl:template match="/">
		<xsl:apply-templates select="//m:content/m:edition"/>
	</xsl:template>

	<xsl:template match="m:edition">
		<xsl:apply-templates select="
			meta:edition(@ref)
				//m:content
					//m:document
						[@ref]
						[not(ancestor::m:main)]
		"/>
	</xsl:template>

	<xsl:template match="m:document">
		<xsl:value-of select="$xwikiBaseUrl"/>
		<xsl:text>&amp;page=texts.</xsl:text>
		<xsl:value-of select="substring-after(@ref, 'doc_')"/>
		<xsl:text>&amp;edition=</xsl:text>
		<xsl:value-of select="substring-after(ancestor::m:edition/@xml:id, 'edition_')"/>
		<xsl:text>&#x0A;</xsl:text>
	</xsl:template>

</xsl:stylesheet>
