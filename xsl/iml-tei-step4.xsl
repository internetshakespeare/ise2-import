<xsl:stylesheet
	version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	exclude-result-prefixes="#all"
	xmlns="http://www.tei-c.org/ns/1.0"
	xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
	xmlns:saxon="http://saxon.sf.net/"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0"
>

<xd:doc scope="stylesheet">
	<xd:desc>
		<xd:p><xd:b>Author:</xd:b> mtaexr</xd:p>
		<xd:p>
			This is the fourth and final step in a multi-step process to convert IML
			to TEI. This step cleans up a lot of superfluous tagging and links
			together part lines.
		</xd:p>
	</xd:desc>
</xd:doc>

<xsl:output encoding="UTF-8" method="xml" indent="true" saxon:suppress-indentation="hi g"/>
<xsl:variable name="pageMarkup" select="('pb', 'cb', 'fw')"/>

<!-- drop line-endings at mode changes (captured by other markup) -->
<xsl:template match="
	lb
		[empty(@type)]
		[
			preceding::node()[1]
				[self::milestone[@type='mode']]
		]
"/>

<!-- drop consecutive line-endings (blank lines are different) -->
<xsl:template match="
	lb
		[empty(@type)]
		[
			preceding::node()[1]
				[self::lb[empty(@type)]]
		]
"/>

<!-- drop the initial lb in 2nd+ ab of a speech (left over from before ab introduced) -->
<xsl:template match="sp/ab[preceding-sibling::ab]/*[1][self::lb][empty(@type)]"/>

<!-- drop empty paragraphs -->
<xsl:template match="text//p[empty(*)][empty(text()[matches(.,'\S')])]"/>

<!-- drop empty verse lines -->
<xsl:template match="l[empty(*)][empty(text()[matches(.,'\S')])]"/>

<!-- drop empty formworks -->
<xsl:template match="fw[empty(*)][empty(text()[matches(.,'\S')])]"/>

<!-- unwrap page markup breaks from verse lines or paragraphs -->
<xsl:template match="
	l
		[exists(*[local-name(.) = $pageMarkup])]
		[empty(*[local-name(.) != $pageMarkup])]
		[empty(text()[matches(., '\S')])]
	|
	p
		[exists(*[local-name(.) = $pageMarkup])]
		[empty(*[local-name(.) != $pageMarkup])]
		[empty(text()[matches(., '\S')])]
">
	<xsl:apply-templates/>
</xsl:template>

<!-- drop MODE milestones, now that we've finished using them -->
<xsl:template match="milestone[@type='mode']"/>

<!-- convert part-line milestones into @part, @next, @prev -->
<xsl:template match="l">
	<!-- part-line marker may be inside, or just before -->
	<xsl:variable name="prevLine" select="preceding::l[1]"/>
	<xsl:variable name="part" as="element()?">
		<xsl:choose>
			<xsl:when test="descendant::milestone[@unit='linepart']">
				<xsl:sequence select="descendant::milestone[@unit='linepart'][1]"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="
					preceding::milestone[@unit='linepart'][1]
						[not($prevLine >> .)]
						[empty(ancestor::l)]
				"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:copy>
		<xsl:if test="exists($part)">
			<xsl:variable name="next" select="$part/following::milestone[@unit='linepart'][1]"/>
			<xsl:variable name="prev" select="$part/preceding::milestone[@unit='linepart'][1]"/>
			<xsl:attribute name="xml:id" select="generate-id(.)"/>
			<xsl:attribute name="part" select="upper-case($part/@n)"/>
			<xsl:if test="$part/@n = ('i', 'm')">
				<xsl:variable name="nextLine" as="element()?" select="
					if ($next/ancestor::l) then $next/ancestor::l[1]
					else $next/following::l[1]
				"/>
				<xsl:if test="not($next/@n = ('m','f')) or empty($nextLine)">
					<xsl:message terminate="yes">
						Can't find next part of split-line
						near TLN <xsl:value-of select="preceding::lb[@type='tln'][1]/@n"/>
					 </xsl:message>
				</xsl:if>
				<xsl:attribute name="next" select="concat('#',generate-id($nextLine))"/>
			</xsl:if>
			<xsl:if test="$part/@n = ('m', 'f')">
				<xsl:variable name="prevLine" select="
					if ($prev/ancestor::l) then $prev/ancestor::l[1]
					else $prev/following::l[1]
				"/>
				<xsl:if test="not($prev/@n = ('m','i')) or empty($prevLine)">
					<xsl:message terminate="yes">
						Can't find previous part of split-line
						near TLN <xsl:value-of select="preceding::lb[@type='tln'][1]/@n"/>
					 </xsl:message>
				</xsl:if>
				<xsl:attribute name="prev" select="concat('#',generate-id($prevLine))"/>
			</xsl:if>
		</xsl:if>
		<xsl:apply-templates select="@*|node()"/>
	</xsl:copy>
</xsl:template>

<!-- drop part-line milestones now that we've folded them into line attrs -->
<xsl:template match="milestone[@unit='linepart']"/>

<!-- leave everything else as-is -->
<xsl:template match="@*|node()">
	<xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>
</xsl:template>

</xsl:stylesheet>
