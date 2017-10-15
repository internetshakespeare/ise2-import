<!--
    Convert an XWiki text from ISE2 to TEI for ISE3.

    Authors:
        Joey Takeda <joey.takeda@gmail.com>
        Maxwell Terpstra <terpstra@alumni.uvic.ca>
-->
<xsl:stylesheet
	version="3.0"
	xmlns="http://www.tei-c.org/ns/1.0"
	xmlns:local="local:/"
	xmlns:ilink="http://ise3.uvic.ca/ns/ise2-import/ilink"
	xmlns:m="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/text"
	xmlns:meta="http://ise3.uvic.ca/ns/ise2-import/metadata"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:util="http://ise3.uvic.ca/ns/ise2-import/util"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	exclude-result-prefixes="#all"
>
	<xsl:import href="global.xsl"/>
	<xsl:include href="ilink.xsl"/>
	<xsl:output indent="yes"/>

	<xsl:variable name="uriRex" select="'^(.*/)?([^/_]+)_([^/]+)\.xml$'"/>

	<xsl:variable name="metadataDoc" select="
		meta:document(replace(document-uri(), $uriRex, 'doc_$3'))
	"/>
	<xsl:variable name="work" select="replace(document-uri(), $uriRex, '$2')"/>
	<xsl:variable name="workIds" select="$taxonomies//tei:taxonomy[@xml:id='iseWorks']/descendant::tei:category/@xml:id"/>
	<xsl:variable name="docClass" select="$metadataDoc//m:documentClass"/>

	<xsl:template match="/">
		<xsl:sequence select="util:xml-model(concat('../sch/', $site, '.rng'))"/>
		<xsl:sequence select="util:xml-model(concat('../sch/', $site, '.sch'))"/>
		<TEI>
			<xsl:attribute name="xml:id" select="
				replace(document-uri(), $uriRex, 'ise$3')
			"/>
			<xsl:apply-templates select="$metadataDoc/m:document/m:head"/>
			<xsl:apply-templates select="/content"/>
		</TEI>
	</xsl:template>

	<xsl:template match="m:head">
		<teiHeader>
			<fileDesc>
				<titleStmt>
					<xsl:sequence select="meta:full-title(m:titles[1])"/>
					<xsl:apply-templates select="m:resp/m:agent"/>
				</titleStmt>
				<publicationStmt copyOf="global:publicationStmt">
					<publisher>Internet Shakespeare Editions</publisher>
				</publicationStmt>
				<sourceDesc>
					<p>Born digital.</p>
				</sourceDesc>
			</fileDesc>
			<xsl:variable name="docType" as="xs:string+">
				<xsl:choose>
					<xsl:when test="$docClass = 'dramaticWork'">idtPrimary</xsl:when>
					<xsl:otherwise>idtBornDigital</xsl:otherwise>
				</xsl:choose>
				<xsl:choose>
					<xsl:when test="$docClass = 'bibliography'">idtParatextBibl</xsl:when>
					<xsl:when test="$docClass = 'chronology'">idtParatextChronology</xsl:when>
					<xsl:when test="$docClass = 'glossary'">idtParatextGloss</xsl:when>
					<xsl:when test="$docClass = 'characters'">idtParatextCharacters</xsl:when>
					<xsl:when test="$docClass = 'footnotes'">idtParatext</xsl:when>
					<xsl:when test="$docClass = 'teachingNotes'">idtParatextPedagogical</xsl:when>
					<xsl:when test="$docClass = 'genIntro'">idtParatextCritIntro</xsl:when>
					<xsl:when test="$docClass = 'criticalSurvey'">idtParatextHistCrit</xsl:when>
					<xsl:when test="$docClass = 'performanceHistory'">idtParatextHistPerf</xsl:when>
					<xsl:when test="$docClass = 'textualHistory'">idtParatextHistText</xsl:when>
					<xsl:when test="$docClass = 'dramaticWork'">idtParatext</xsl:when>
					<xsl:otherwise>idtParatext</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<profileDesc>
				<textClass>
					<xsl:if test="concat('ise', $work) = $workIds">
						<catRef scheme="idt:iseWorks" target="idt:ise{$work}"/>
					</xsl:if>
					<xsl:for-each select="$docType">
						<catRef scheme="idt:iseDocumentTypes" target="idt:{.}"/>
					</xsl:for-each>
				</textClass>
			</profileDesc>
			<encodingDesc>
				<p>Encoding description coming soon.</p>
			</encodingDesc>
			<revisionDesc status="converted">
				<xsl:sequence select="util:conversion-change()"/>
			</revisionDesc>
		</teiHeader>
	</xsl:template>

	<xsl:template match="m:agent">
		<xsl:sequence select="meta:respStmt-for-agent(.)"/>
	</xsl:template>

	<xsl:template match="content">
		<text>
			<body>
				<xsl:variable name="docContent" as="element(tei:div)+">
					<xsl:for-each-group select="*" group-starting-with="h1">
						<div>
							<xsl:if test="current-group()[1]/self::h1 and current-group()[1]/@id">
								<xsl:attribute name="xml:id">
									<xsl:value-of select="replace(current-group()[1]/@id, ':', '_')"/>
								</xsl:attribute>
							</xsl:if>
							<xsl:for-each-group select="current-group()" group-starting-with="h2">
								<xsl:choose>
									<xsl:when test="current-group()[1]/self::h2">
										<div>
											<xsl:if test="current-group()[1]/@id">
												<xsl:attribute name="xml:id">
													<xsl:value-of select="replace(current-group()[1]/@id, ':', '_')"/>
												</xsl:attribute>
											</xsl:if>
											<xsl:for-each-group select="current-group()" group-starting-with="h3">
												<xsl:choose>
													<xsl:when test="current-group()[1]/self::h3">
														<div>
															<xsl:if test="current-group()[1]/@id">
																<xsl:attribute name="xml:id">
																	<xsl:value-of select="replace(current-group()[1]/@id, ':', '_')"/>
																</xsl:attribute>
															</xsl:if>
															<xsl:for-each-group select="current-group()" group-starting-with="h4">
																<xsl:choose>
																	<xsl:when test="current-group()[1]/self::h4">
																		<div>
																			<xsl:if test="current-group()[1]/@id">
																				<xsl:attribute name="xml:id">
																					<xsl:value-of select="replace(current-group()[1]/@id, ':', '_')"/>
																				</xsl:attribute>
																				<xsl:apply-templates select="current-group()"/>
																			</xsl:if>
																		</div>
																	</xsl:when>
																	<xsl:otherwise>
																		<xsl:apply-templates select="current-group()"/>
																	</xsl:otherwise>
																</xsl:choose>
															</xsl:for-each-group>
														</div>
													</xsl:when>
													<xsl:otherwise>
														<xsl:apply-templates select="current-group()"/>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:for-each-group>
										</div>
									</xsl:when>
									<xsl:otherwise>
										<xsl:apply-templates select="current-group()"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each-group>
						</div>
					</xsl:for-each-group>
				</xsl:variable>
				<xsl:sequence select="local:cutDivs($docContent)"/>
			</body>
		</text>
	</xsl:template>

	<!-- gets rid of container divs that are useless but difficult to
	mitigate in the ever-nesting for each groups above.-->
	<xsl:function name="local:cutDivs">
		<xsl:param name="elem"/>
		<xsl:choose>
			<xsl:when test="$elem[self::tei:div][every $n in child::* satisfies $n[self::tei:div]]">
				<xsl:sequence select="local:cutDivs($elem/*)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="$elem"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<xsl:template match="h1 | h2 | h3 | h4">
		<head>
			<xsl:apply-templates/>
		</head>
	</xsl:template>

	<xsl:template match="div | span">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="div[@loc]">
		<note type="marginal" place="{@loc}">
			<xsl:if test="@style">
				<xsl:attribute name="style" select="@style"/>
			</xsl:if>
			<xsl:apply-templates/>
		</note>
	</xsl:template>

	<xsl:template match="div[@class = 'wikimodel-emptyline']">
		<!--This is weird formatting stuff but I don't think it really matters-->
		<lb/>
	</xsl:template>

	<xsl:template match="(div | span | a)[@id][normalize-space(.) = '']">
		<anchor>
			<xsl:attribute name="n" select="@id"/>
		</anchor>
	</xsl:template>

	<xsl:template match="p">
		<p>
			<xsl:choose>
				<xsl:when test="@style = 'text-align:center'">
					<xsl:attribute name="rendition">simple:center</xsl:attribute>
				</xsl:when>
				<xsl:when test="@style">
					<!-- this probably indicates poor semantic tagging... -->
					<xsl:copy-of select="@style"/>
				</xsl:when>
			</xsl:choose>
			<xsl:apply-templates/>
		</p>
	</xsl:template>

	<xsl:template match="br">
		<lb/>
	</xsl:template>

	<xsl:template match="blockquote">
		<quote>
			<xsl:apply-templates/>
		</quote>
	</xsl:template>

	<xsl:template match="ol | ul | dl">
		<xsl:choose>
			<xsl:when test="$docClass = 'bibliography'">
				<listBibl>
					<xsl:apply-templates/>
				</listBibl>
			</xsl:when>
			<xsl:otherwise>
				<list>
					<xsl:apply-templates/>
				</list>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="li | dd">
		<xsl:choose>
			<xsl:when test="$docClass = 'bibliography'">
				<bibl>
					<xsl:apply-templates/>
				</bibl>
			</xsl:when>
			<xsl:otherwise>
				<item>
					<xsl:apply-templates/>
				</item>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="dt">
		<label>
			<xsl:apply-templates/>
		</label>
	</xsl:template>

	<xsl:template match="table">
		<table>
			<xsl:apply-templates/>
		</table>
	</xsl:template>

	<xsl:template match="tr">
		<row>
			<xsl:apply-templates/>
		</row>
	</xsl:template>

	<xsl:template match="td">
		<cell>
			<xsl:apply-templates/>
		</cell>
	</xsl:template>

	<xsl:template match="sup">
		<hi rendition="simple:superscript">
			<xsl:apply-templates/>
		</hi>
	</xsl:template>

	<xsl:template match="em">
		<xsl:choose>
			<xsl:when test="$docClass = 'bibliography' and (ancestor::ol or ancestor::ul)">
				<title level="m">
					<xsl:apply-templates/>
				</title>
			</xsl:when>
			<xsl:otherwise>
				<hi rendition="simple:italic">
					<xsl:apply-templates/>
				</hi>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="strong">
		<hi rendition="simple:bold">
			<xsl:apply-templates/>
		</hi>
	</xsl:template>

	<!-- dels are probably wiki markup errors, but we'll let a human decide later -->
	<xsl:template match="del">
		<hi rendition="simple:strikethrough">
			<xsl:apply-templates/>
		</hi>
	</xsl:template>

	<xsl:template match="hr">
		<milestone unit="section" rend="horizontal-rule"/>
	</xsl:template>

	<xsl:template match="a[@href]">
		<ref target="{@href}">
			<xsl:apply-templates/>
		</ref>
	</xsl:template>

	<xsl:template match="*" priority="-1">
		<xsl:message>Element <xsl:value-of select="local-name()"/> not being processed. (<xsl:for-each select="@*">@<xsl:value-of select="local-name()"/>: <xsl:value-of select="."/><xsl:if test="not(last())">, </xsl:if></xsl:for-each>)</xsl:message>
	</xsl:template>

</xsl:stylesheet>
