<xsl:stylesheet
	version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
	exclude-result-prefixes="#all"
	xmlns="http://www.tei-c.org/ns/1.0"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0"
>

<xd:doc scope="stylesheet">
	<xd:desc>
		<xd:p><xd:b>Author:</xd:b> mtaexr</xd:p>
		<xd:p>
			Step 2 in a multi-step process to convert IML to TEI. This step
			does some cleanup that can only be figured out after the bulk of TEI
			conversion is done.
		</xd:p>
	</xd:desc>
</xd:doc>

<!-- drop extra <J> milestones (no text between stop/start) -->
<xsl:template match="*:HORZAL[@T='J'][@SWITCH='ON']">
	<xsl:variable name="prev" select="preceding::*:HORZAL[@T='J'][@SWITCH='OFF'][1]"/>
	<xsl:if test="empty($prev) or exists(//text()[current() >> .][. >> $prev][normalize-space(.) != ''])">
		<xsl:copy-of select="."/>
	</xsl:if>
</xsl:template>
<xsl:template match="*:HORZAL[@T='J'][@SWITCH='OFF']">
	<xsl:variable name="next" select="following::*:HORZAL[@T='J'][@SWITCH='ON'][1]"/>
	<xsl:if test="empty($next) or exists(//text()[$next >> .][. >> current()][normalize-space(.) != ''])">
		<xsl:copy-of select="."/>
	</xsl:if>
</xsl:template>

<!-- only keep editor's line-breaks in contexts where they are meaningful -->
<xsl:template match="lb[@ed='this']">
	<xsl:variable name="prev" select="preceding::lb[@ed='this'][1]"/>
	<xsl:choose>
		<!-- redundant if we already have a SHY (aka {-}) -->
		<xsl:when test="
			preceding::lb[@type='hyphenInWord'][not($prev >> .)]
		"/>
		<!-- keep if it's in an obvious content block -->
		<xsl:when test="
			ancestor::head or
			ancestor::ab or
			ancestor::lg or
			ancestor::l or
			ancestor::p or
			ancestor::stage or
			ancestor::note or
			ancestor::closer
		">
			<lb/>
		</xsl:when>
		<!-- throw them out everywhere else -->
		<xsl:otherwise/>
	</xsl:choose>
</xsl:template>

<xsl:template match="@*|node()">
	<xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>
</xsl:template>

</xsl:stylesheet>
