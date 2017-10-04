<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
	version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
	exclude-result-prefixes="#all"
	xmlns="http://www.tei-c.org/ns/1.0"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0"
	xmlns:hcmc="http://hcmc.uvic.ca/ns"
	xmlns:xh="http://www.w3.org/1999/xhtml"
	xmlns:isetext="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/text"
>
	<xd:doc scope="stylesheet">
		<xd:desc>
			<xd:p><xd:b>Created on:</xd:b> Nov 3, 2015</xd:p>
			<xd:p><xd:b>Author:</xd:b> jtakeda</xd:p>
			<xd:p><xd:b>Author:</xd:b> mtaexr</xd:p>
			<xd:p>
				This is step 3 in a multi-step process to convert IML to TEI.
				This step creates the particDesc for speakers in modern texts
				and fixes up lineation and line grouping.
			</xd:p>
		</xd:desc>
	</xd:doc>

	<xsl:param name="modern" as="xs:boolean"/>
	<xsl:variable name="newDocId" select="replace(document-uri(.), '^(.*/)|\.xml$', '')"/>

	<xsl:strip-space elements="l"/>

	<xsl:template match="particDesc">
		<xsl:variable name="speakers" select="//TEI/descendant::sp[@who]"/>
		<xsl:variable name="speakerRefs" select="for $s in $speakers return tokenize($s/@who,'\s+')"/>
		<xsl:variable name="speakerTokens" select="for $s in $speakerRefs[starts-with(.,'sp:')] return substring-after($s,'sp:')"/>
		<xsl:variable name="uniqueSpeakers" select="distinct-values($speakerTokens)"/>
		<xsl:if test="$modern and count($uniqueSpeakers) gt 1"> <!-- no particDesc in OS -->
			<particDesc>
				<listPerson>
					<xsl:for-each select="$uniqueSpeakers">
						<person>
							<xsl:attribute name="xml:id" select="concat($newDocId, '_', .)"/>
							<persName>
								 <reg><xsl:value-of select="."/></reg>
							</persName>
						</person>
					</xsl:for-each>
				</listPerson>
			</particDesc>
		</xsl:if>
	</xsl:template>

	<!--Speaker tags-->
	<xsl:template match="sp/@who">
		<xsl:if test="$modern"> <!-- don't keep @who from OS -->
			<xsl:attribute name="who">
				<xsl:variable name="whoTokens" select="tokenize(., '\s+')"/>
				<xsl:variable name="whoNames" select="for $n in $whoTokens return substring-after($n, 'sp:')"/>
				<xsl:variable name="newRefs" select="for $w in $whoNames return concat('#', $newDocId, '_', $w)"/>
				<xsl:value-of select="string-join($newRefs,' ')"/>
			</xsl:attribute>
		</xsl:if>
	</xsl:template>

	<xsl:function name="hcmc:mustWrap" as="xs:boolean">
		<xsl:param name="chunk" as="node()*"/>
		<xsl:sequence select="exists(
			$chunk/descendant-or-self::text()[matches(., '\S')]
			except
			(
				$chunk/descendant-or-self::stage,
				$chunk/descendant-or-self::fw,
				$chunk/descendant-or-self::head,
				$chunk/descendant-or-self::closer,
				$chunk/descendant-or-self::lg,
				$chunk/descendant-or-self::figure,
				$chunk/descendant-or-self::note
			)//text()
		)"/>
	</xsl:function>

	<!-- separates content of into "lines" between tei:lb's -->
	<xsl:template name="line-chunks">
		<xsl:param name="element" as="xs:string"/>
		<xsl:param name="p" as="element()"/>
		<xsl:param name="start" as="element(milestone)?"/>
		<xsl:param name="end" as="element(milestone)?"/>
		<xsl:param name="lb" as="element(lb)*"/>
		<xsl:variable name="chunk" as="node()*">
			<xsl:apply-templates select="$p/node()">
				<xsl:with-param tunnel="yes" name="leftBound" select="$start"/>
				<xsl:with-param tunnel="yes" name="rightBound" select="($lb, $end)[1]"/>
				<xsl:with-param tunnel="yes" name="dropLb" select="true()"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="hcmc:mustWrap($chunk)">
				<xsl:element name="{$element}">
					<xsl:sequence select="$chunk"/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="$chunk" mode="strip-quotes"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:for-each select="$lb">
			<xsl:variable name="i" select="position()"/>
			<xsl:variable name="chunk" as="node()*">
				<xsl:apply-templates select="$p/node()">
					<xsl:with-param tunnel="yes" name="leftBound" select="$lb[$i]"/>
					<xsl:with-param tunnel="yes" name="rightBound" select="($lb[$i + 1], $end)[1]"/>
					<xsl:with-param tunnel="yes" name="dropLb" select="true()"/>
				</xsl:apply-templates>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="hcmc:mustWrap($chunk)">
					<xsl:element name="{$element}">
						<xsl:sequence select="$chunk"/>
					</xsl:element>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="$chunk" mode="strip-quotes"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="quote" mode="strip-quotes">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- wraps tei:p content appropriately based on the prevailing mode -->
	<xsl:template name="mode-chunk">
		<xsl:param name="p" as="element(p)"/>
		<xsl:param name="lb" as="element(lb)*"/>
		<xsl:param name="start" as="element(milestone)?"/><!-- @type='mode' -->
		<xsl:param name="end" as="element(milestone)?"/><!-- @type='mode' -->
		<xsl:variable name="_lb" select="$lb[not($start >> .)][not(. >> $end)]"/>
		<xsl:choose>
			<xsl:when test="
				empty(
					$p//text()[not(. >> $end)][not($start >> .)][matches(., '\S')]
					except
					(
						$p//stage,
						$p//fw,
						$p//head,
						$p//closer,
						$p//lg,
						$p//figure,
						$p//note
					)//text()
				)
			">
				<!-- no text to lineate, so just pass through -->
				<xsl:apply-templates select="$p/node()">
					<xsl:with-param tunnel="yes" name="leftBound" select="$start"/>
					<xsl:with-param tunnel="yes" name="rightBound" select="$end"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:when test="empty($start) or $start/@subtype = ('uncertain', 'end')">
				<ab>
					<xsl:apply-templates select="$p/node()">
						<xsl:with-param tunnel="yes" name="leftBound" select="$start"/>
						<xsl:with-param tunnel="yes" name="rightBound" select="$end"/>
					</xsl:apply-templates>
				</ab>
			</xsl:when>
			<xsl:when test="$start/@subtype = 'prose'">
				<ab>
					<xsl:apply-templates select="$p/node()">
						<xsl:with-param tunnel="yes" name="leftBound" select="$start"/>
						<xsl:with-param tunnel="yes" name="rightBound" select="$end"/>
						<!-- line breaks in modern IML prose are not meaningful -->
						<xsl:with-param tunnel="yes" name="dropLb" select="true()"/>
					</xsl:apply-templates>
				</ab>
			</xsl:when>
			<xsl:when test="$start/@subtype = 'verse'">
					<xsl:call-template name="line-chunks">
						<xsl:with-param name="element">l</xsl:with-param>
						<xsl:with-param name="p" select="$p"/>
						<xsl:with-param name="start" select="$start"/>
						<xsl:with-param name="end" select="$end"/>
						<xsl:with-param name="lb" select="$_lb"/>
					</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message terminate="yes">
					<xsl:text>Unrecognized MODE type "</xsl:text>
					<xsl:value-of select="@subtype"/>
					<xsl:text>"</xsl:text>
				</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- wraps tei:p content appropriately based on the prevailing mode -->
	<xsl:template name="align-chunk">
			<xsl:param name="p" as="element(p)"/>
			<xsl:param name="lb" as="element(lb)*"/>
			<xsl:param name="start" as="element()?"/><!-- HORZAL -->
			<xsl:param name="end" as="element()?"/><!-- HORZAL -->
			<xsl:variable name="_lb" select="$lb[not($start >> .)][not(. >> $end)]"/>
			<xsl:choose>
					<xsl:when test="
							empty(
									$p//text()[not(. >> $end)][not($start >> .)][matches(., '\S')]
									except
									(
											$p//stage,
											$p//fw,
											$p//head,
											$p//closer,
											$p//lg,
											$p//figure,
											$p//note
									)//text()
							)
					">
							<!-- no text to lineate, so just pass through -->
							<xsl:apply-templates select="$p/node()">
									<xsl:with-param tunnel="yes" name="leftBound" select="$start"/>
									<xsl:with-param tunnel="yes" name="rightBound" select="$end"/>
							</xsl:apply-templates>
					</xsl:when>
					<xsl:otherwise>
							<ab>
									<xsl:if test="$start/@SWITCH = 'ON'">
											<xsl:attribute name="rendition">simple:justify</xsl:attribute>
									</xsl:if>
									<xsl:apply-templates select="$p/node()">
											<xsl:with-param tunnel="yes" name="leftBound" select="$start"/>
											<xsl:with-param tunnel="yes" name="rightBound" select="$end"/>
									</xsl:apply-templates>
							</ab>
					</xsl:otherwise>
			</xsl:choose>
	</xsl:template>

	<!-- break apart paragraphs at line breaks -->
	<xsl:template match="text//p">
		<xsl:variable name="thisP" select="."/>
		<xsl:variable name="lb" select="
			descendant::lb[empty(@type)] except descendant::note//lb
		"/>
		<xsl:choose>
			<xsl:when test="$modern">
				<xsl:variable name="startMode" select="preceding::milestone[@type='mode'][1]"/>
				<xsl:variable name="internalModes" select="descendant::milestone[@type='mode']"/>
				<xsl:call-template name="mode-chunk">
					<xsl:with-param name="start" select="$startMode"/>
					<xsl:with-param name="end" select="$internalModes[1]"/>
					<xsl:with-param name="p" select="$thisP"/>
					<xsl:with-param name="lb" select="$lb"/>
				</xsl:call-template>
				<xsl:for-each select="$internalModes">
					<xsl:variable name="i" select="position()"/>
					<xsl:call-template name="mode-chunk">
						<xsl:with-param name="start" select="$internalModes[$i]"/>
						<xsl:with-param name="end" select="$internalModes[$i + 1]"/>
						<xsl:with-param name="p" select="$thisP"/>
						<xsl:with-param name="lb" select="$lb"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="startAlign" select="preceding::*:HORZAL[@T='J'][1]"/>
				<xsl:variable name="internalAligns" select="descendant::*:HORZAL[@T='J']"/>
				<xsl:call-template name="align-chunk">
						<xsl:with-param name="start" select="$startAlign"/>
						<xsl:with-param name="end" select="$internalAligns[1]"/>
						<xsl:with-param name="p" select="$thisP"/>
						<xsl:with-param name="lb" select="$lb"/>
				</xsl:call-template>
				<xsl:for-each select="$internalAligns">
						<xsl:variable name="i" select="position()"/>
						<xsl:call-template name="align-chunk">
								<xsl:with-param name="start" select="$internalAligns[$i]"/>
								<xsl:with-param name="end" select="$internalAligns[$i + 1]"/>
								<xsl:with-param name="p" select="$thisP"/>
								<xsl:with-param name="lb" select="$lb"/>
						</xsl:call-template>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- properly lineate line groups -->
	<xsl:template match="lg"> <!-- note: these only appear in modern -->
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:call-template name="line-chunks">
				<xsl:with-param name="element">l</xsl:with-param>
				<xsl:with-param name="p" select="l"/>
				<xsl:with-param name="lb" select="
					l//lb[empty(@type)] except l//note//lb
				"/>
			</xsl:call-template>
		</xsl:copy>
	</xsl:template>

	<!-- drop line breaks that have been used for chunking -->
	<xsl:template match="lb[empty(@type)]">
		<xsl:param tunnel="yes" name="dropLb" select="false()"/>
		<xsl:if test="not($dropLb)">
			<xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>
		</xsl:if>
	</xsl:template>

	<xsl:template match="*:HORZAL" mode="#all"/> <!-- we're done with these now -->

	<!-- if left/rightBound is set, drop elements outside those bounds -->
	<xsl:template match="node()" priority="99">
		<xsl:param tunnel="yes" name="leftBound" as="node()?"/>
		<xsl:param tunnel="yes" name="rightBound" as="node()?"/>
		<xsl:choose>
			<xsl:when test=". >> $rightBound or . is $rightBound"/>
			<xsl:when test="
				. instance of element()
				and
				exists(
					./descendant-or-self::node()
						[not($leftBound >> .)]
						[not(. >> $rightBound or . is $rightBound)]
				)
			">
				<xsl:next-match/>
			</xsl:when>
			<xsl:when test="$leftBound >> ."/>
			<xsl:otherwise>
				<xsl:next-match/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!--Copy everything else-->
	<xsl:template match="node()|@*" priority="-1" mode="#all">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="#current"/>
		</xsl:copy>
	</xsl:template>

</xsl:stylesheet>
