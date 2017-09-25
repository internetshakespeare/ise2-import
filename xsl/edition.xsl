<!--
	Converts ISE2 edition metadata into a TEI edition page for ISE3

	Authors:
	  Joey Takeda <joey.takeda@gmail.com>
	  Maxwell Terpstra <terpstra@alumni.uvic.ca>
-->
<xsl:stylesheet
	version="2.0"
	xmlns="http://www.tei-c.org/ns/1.0"
	xmlns:h="http://www.w3.org/1999/xhtml"
	xmlns:ilink="http://ise3.uvic.ca/ns/ise2-import/ilink"
	xmlns:img="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/image.rng"
	xmlns:meta="http://ise3.uvic.ca/ns/ise2-import/metadata"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:user="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/users"
	xmlns:util="http://ise3.uvic.ca/ns/ise2-import/util"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xpath-default-namespace="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/text"
	exclude-result-prefixes="#all"
>
	<xsl:import href="global.xsl"/>
	<xsl:include href="ilink.xsl"/>

	<xsl:output indent="yes"/>

	<xsl:variable name="workId" select="concat('ise', substring-after(//edition/@xml:id, 'edition_'))"/>
	<xsl:variable name="docId" select="concat($workId, '_edition')"/>

	<xsl:template match="/">
		<xsl:sequence select="util:xml-model(concat('../sch/', $site, '.rng'))"/>
		<xsl:sequence select="util:xml-model(concat('../sch/', $site, '.sch'))"/>
		<TEI version="5.0">
			<xsl:attribute name="xml:id" select="$docId"/>
			<teiHeader>
				<!-- intentionally excluded description (redundant with document descriptions) -->
				<!-- no edition uses: externalIdentifiers, rights, thumbnail -->
				<fileDesc>
					<titleStmt>
						<xsl:sequence select="meta:full-title(//head/titles)"/>
						<xsl:apply-templates select="//head/resp/agent"/>
					</titleStmt>
					<publicationStmt copyOf="global:publicationStmt"/>
					<seriesStmt>
						<xsl:sequence select="meta:title(//head/titles)"/>
					</seriesStmt>
					<sourceDesc>
						<p>Born digital.</p>
					</sourceDesc>
				</fileDesc>
				<profileDesc>
					<textClass>
						<!-- FIXME: these need to be site-generic -->
						<catRef scheme="idt:iseDocumentTypes" target="idt:idtBornDigital"/>
						<catRef scheme="idt:iseDocumentTypes" target="idt:idtEdition"/>
						<!-- FIXME: handle apocrypha? -->
						<catRef scheme="idt:iseWorks" target="idt:{$workId}"/>
						<!-- FIXME: published in Broadview? Peer reviewed? -->
					</textClass>
				</profileDesc>
				<encodingDesc>
					<listPrefixDef copyOf="global:listPrefixDef"/>
					<projectDesc copyOf="global:projectDesc"/>
					<editorialDecl copyOf="global:editorialDecl_general"/>
				</encodingDesc>
				<revisionDesc status="converted">
					<change who="{$siteOrgRef}" when="{current-date()}">
						<xsl:text>Converted from ISE2 XML via </xsl:text>
						<ref target="https://github.com/internetshakespeare/ise2-import">import script</ref>
						<xsl:text>.</xsl:text>
					</change>
					<xsl:apply-templates select="//filePublished"/>
					<!-- fileCreated is probably wrong, and not particularly relevant -->
					<!-- subjectCreated and subjectPublished aren't used in editions -->
				</revisionDesc>
			</teiHeader>
			<text>
				<front>
					<xsl:apply-templates select="//head/titlePageImage"/>
					<docTitle>
						<titlePart>
							<xsl:sequence select="meta:title(//head/titles)"/>
						</titlePart>
					</docTitle>
					<xsl:apply-templates select="//content/credits/agent"/>
				</front>
				<body>
					<xsl:apply-templates select="//content/* except //content/credits"/>
					<!-- FIXME: what to do with references/document[@rel='characters'] and content/characters/document ? -->
				</body>
			</text>
		</TEI>
	</xsl:template>

	<xsl:template match="resp/agent">
		<xsl:sequence select="meta:respStmt-for-agent(.)"/>
	</xsl:template>

	<xsl:template match="filePublished">
		<change who="{$siteOrgRef}">
			<!-- These are borrwed from TEI already -->
			<xsl:copy-of select="@when, @notBefore, @notAfter, @cert"/>
			<!-- Editions don't use @earliest -->
			<xsl:text>Edition first published on ISE2.</xsl:text>
		</change>
	</xsl:template>

	<xsl:template match="titlePageImage">
		<figure>
			<xsl:apply-templates/>
		</figure>
	</xsl:template>

	<xsl:template match="titlePageImage/img:webReady">
		<graphic url="{@href}">
			<xsl:apply-templates/>
		</graphic>
	</xsl:template>

	<xsl:template match="titlePageImage/img:source">
		<xsl:comment>
			<xsl:text>FIXME: decide what to do with archival image at </xsl:text>
			<xsl:value-of select="@href"/>
		</xsl:comment>
	</xsl:template>

	<xsl:template match="titlePageImage/caption">
		<desc><xsl:apply-templates/></desc>
	</xsl:template>

	<xsl:template match="credits/agent">
		<byline>
			<xsl:variable name="respStmt" select="meta:respStmt-for-agent(.)"/>
			<xsl:value-of select="$respStmt/tei:resp"/>
			<xsl:text>: </xsl:text>
			<xsl:copy-of select="$respStmt/tei:persName"/>
		</byline>
	</xsl:template>

	<!-- FIXME -->
	<xsl:template match="characters"/>

	<xsl:template match="introduction | main | supplements">
		<xsl:if test=".//document"> <!-- note: no editions currently link to other editions -->
			<div>
				<head>
					<xsl:choose>
						<xsl:when test="self::introduction">
							<xsl:text>Introduction</xsl:text>
						</xsl:when>
						<xsl:when test="self::main">
							<xsl:text>Texts of this edition</xsl:text>
						</xsl:when>
						<xsl:when test="self::supplements">
							<xsl:text>Supplementary materials</xsl:text>
						</xsl:when>
					</xsl:choose>
				</head>
				<xsl:apply-templates select="p"/>
				<xsl:choose>
					<xsl:when test="g">
						<xsl:apply-templates select="g"/>
					</xsl:when>
					<xsl:otherwise>
						<list>
							<xsl:apply-templates select="* except p"/>
						</list>
					</xsl:otherwise>
				</xsl:choose>
			</div>
		</xsl:if>
	</xsl:template>

	<xsl:template match="g">
		<list>
			<xsl:apply-templates select="h"/>
			<xsl:apply-templates select="* except h"/>
		</list>
	</xsl:template>

	<xsl:template match="g/h">
		<head><xsl:apply-templates/></head>
	</xsl:template>

	<xsl:template match="p">
		<p><xsl:apply-templates/></p>
	</xsl:template>

	<xsl:template match="document">
		<xsl:variable name="thisElem" select="."/>
		<xsl:variable name="editionAuthors" select="//credits/agent[@role='author']"/>
		<xsl:variable name="editionEditors" select="//credits/agent[@role='editor']"/>
		<xsl:variable name="documentMeta" select="meta:document(@ref)"/>
		<item>
			<ref target="{concat('doc:', $site, substring-after(@ref, 'doc_'))}">
				<xsl:choose>
					<xsl:when test="ancestor::main">
						<!-- note: no titles currently using markup, so string manipulation is sufficient -->
						<xsl:variable name="edTitle" select="normalize-space(//head//title)"/>
						<xsl:variable name="title" select="normalize-space($documentMeta//titles/title)"/>
						<xsl:variable name="witness" select="normalize-space($documentMeta//titles/witness)"/>
						<title>
							<!-- trim edition name and ':' from front -->
							<xsl:value-of select="
								if (starts-with($title, $edTitle))
								then replace(
									substring-after($title, $edTitle),
									'^\s*:\s*',
									''
								)
								else $title
							"/>
							<!-- append witness -->
							<xsl:if test="$witness != ''" expand-text="yes"> ({$witness})</xsl:if>
						</title>
					</xsl:when>
					<xsl:otherwise>
						<xsl:sequence select="meta:title($documentMeta//titles)"/>
					</xsl:otherwise>
				</xsl:choose>
			</ref>
			<xsl:if test="ancestor::supplements">
				<xsl:variable name="work" select="
					if (exists($documentMeta//work[@rel='identity']))
					then meta:work($documentMeta//work[@rel='identity']/@ref)
					else ()
				"/>
				<xsl:variable name="authors" select="
					$documentMeta//resp/agent[@role='author'],
					$work//resp/agent[@role='author']
				"/>
				<xsl:variable name="editors" select="
					$documentMeta//resp/agent[@role='editor'][empty(@class)]
				"/>
				<xsl:if test="$authors[not(@user = $editionAuthors/@user)]">
					<xsl:sequence select="util:comma-list(
						for $a in $authors/@user return util:pers-ref($a)
					)"/>
				</xsl:if>
				<xsl:if test="$editors[not(@user = $editionEditors/@user)]">
					<xsl:if test="$authors[not(@user = $editionAuthors/@user)]">.</xsl:if>
					<xsl:text> Edited by </xsl:text>
					<xsl:sequence select="util:comma-list(
						for $e in $editors/@user return util:pers-ref($e)
					)"/>
					<xsl:text>.</xsl:text>
				</xsl:if>
			</xsl:if>
		</item>
	</xsl:template>

	<!-- TODO: these are technically allowed, but none of our editions use them at time of writing -->
	<xsl:template match="edition"/>

	<xsl:template match="h:i">
		<hi rendition="simple:italic"><xsl:apply-templates/></hi>
	</xsl:template>

</xsl:stylesheet>
