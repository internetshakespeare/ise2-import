<!--
	Converts ISE2 stand-off apparatus files to TEI for ISE3

	Authors:
		Joey Takeda <joey.takeda@gmail.com>
		Maxwell Terpstra <terpstra@alumni.uvic.ca>
-->
<xsl:stylesheet
	version="2.0"
	xmlns="http://www.tei-c.org/ns/1.0"
	xmlns:local="local:/"
	xmlns:m="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/text"
	xmlns:meta="http://ise3.uvic.ca/ns/ise2-import/metadata"
	xmlns:saxon="http://saxon.sf.net/"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:util="http://ise3.uvic.ca/ns/ise2-import/util"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	exclude-result-prefixes="#all"
>
	<xsl:import href="global.xsl"/>
	<xsl:include href="ilink.xsl"/>

	<xsl:output method="xml" indent="yes" saxon:suppress-indentation="tei:lb tei:gap tei:hi"/>

	<xsl:variable name="targetId" select="/*/@for"/>
	<xsl:variable name="teiTargetId" select="concat($site, replace($targetId, '^doc_', ''))"/>
	<xsl:variable name="workId" select="replace($targetId, '^doc_|_.*$', '')"/>
	<xsl:variable name="edition" select="meta:edition(concat('edition_', $workId))"/>

	<xsl:template match="/collations">
		<xsl:call-template name="appDoc">
			<xsl:with-param name="type">collations</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="/annotations">
		<xsl:call-template name="appDoc">
			<xsl:with-param name="type">annotations</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="appDoc">
		<xsl:param name="type"/>
		<xsl:sequence select="util:xml-model(concat('../sch/', $site, '.rng'))"/>
		<xsl:sequence select="util:xml-model(concat('../sch/', $site, '.sch'))"/>
		<TEI version="5.0">
			<xsl:attribute name="xml:id" select="concat($teiTargetId, '_', $type)"/>
			<teiHeader>
				<fileDesc>
					<titleStmt>
						<title>
							<xsl:value-of select="util:title-case($type)"/>
							<xsl:text> for </xsl:text>
							<ref target="doc:{$teiTargetId}">
								<xsl:value-of select="$teiTargetId"/>
							</ref>
						</title>
						<xsl:call-template name="resp">
							<xsl:with-param name="type" select="$type"/>
						</xsl:call-template>
					</titleStmt>
					<publicationStmt copyOf="global:publicationStmt"/>
					<notesStmt>
						<relatedItem target="doc:{$teiTargetId}"/>
					</notesStmt>
					<sourceDesc>
						<p>Born digital</p>
					</sourceDesc>
				</fileDesc>
				<profileDesc>
					<textClass>
						<catRef scheme="idt:iseDocumentTypes" target="idt:idtBornDigital"/>
						<catRef scheme="idt:iseDocumentTypes" target="idt:idtApparatus"/>
						<xsl:try>
							<xsl:sequence select="util:catRef-for-work($workId)"/>
							<xsl:catch>
								<xsl:comment>FIXME: no category found for work <xsl:value-of select="$workId"/>; should there be one?</xsl:comment>
							</xsl:catch>
						</xsl:try>
					</textClass>
				</profileDesc>
				<encodingDesc>
					<listPrefixDef>
						<prefixDef ident="tln" matchPattern="(.+)" replacementPattern="doc:{$teiTargetId}#tln-$1">
							<p>The tln prefix def matches a TLN in the target document.</p>
						</prefixDef>
					</listPrefixDef>
					<listPrefixDef copyOf="global:listPrefixDef"/>
					<projectDesc copyOf="global:projectDesc"/>
					<editorialDecl copyOf="global:editorialDecl_{$type}"/>
				</encodingDesc>
				<revisionDesc status="converted">
					<xsl:sequence select="util:conversion-change()"/>
				</revisionDesc>
			</teiHeader>
			<text>
				<body>
					<p>This is a stand-off apparatus file. It is likely not useful without it's <ref target="doc:{$teiTargetId}">target document</ref>.</p>
					<xsl:choose>
						<xsl:when test="$type = 'annotations'">
							<spanGrp>
								<xsl:apply-templates mode="a"/>
							</spanGrp>
						</xsl:when>
						<xsl:when test="$type = 'collations'">
							<listApp>
								<xsl:apply-templates mode="c"/>
							</listApp>
						</xsl:when>
					</xsl:choose>
				</body>
			</text>
		</TEI>
	</xsl:template>

	<xsl:template name="resp">
		<xsl:param name="type"/>
		<xsl:variable name="editor" select="
			$edition//m:head//m:agent
				[@role = 'editor']
				[empty(@class)]
		"/>
		<xsl:if test="empty($editor)">
			<xsl:comment>FIXME: no editor found</xsl:comment>
		</xsl:if>
		<xsl:for-each select="$editor">
			<respStmt>
				<resp>
					<xsl:attribute name="ref">
						<xsl:choose>
							<xsl:when test="$type = 'annotations'">resp:aut_ann</xsl:when>
							<xsl:otherwise>resp:aut_col</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:choose>
						<xsl:when test="$type = 'annotations'">Author of Annotations</xsl:when>
						<xsl:otherwise>Collator</xsl:otherwise>
					</xsl:choose>
				</resp>
				<xsl:sequence select="util:name-for-user(@user)"/>
			</respStmt>
		</xsl:for-each>
	</xsl:template>

<!--Templates specific to annotations-->

	<xsl:template match="note" mode="a">
		<span>
			<xsl:copy-of select="local:appAtts(.)"/>
			<xsl:apply-templates mode="#current"/>
		</span>
	</xsl:template>

	<xsl:template match="level[@n='1']" mode="a">
		<gloss><xsl:apply-templates mode="#current"/></gloss>
	</xsl:template>

	<xsl:template match="level" mode="a">
		<xsl:variable name="type">
			<xsl:choose>
				<xsl:when test="@n = '2'">commentary</xsl:when>
				<xsl:when test="@n = 'perf'">performance</xsl:when>
				<xsl:when test="@n = 'ped'">pedagogical</xsl:when>
				<xsl:otherwise>
					<xsl:message terminate="yes">Unrecognized note level "<xsl:value-of select="@n"/>"</xsl:message>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<note type="{$type}"><xsl:apply-templates mode="#current"/></note>
	</xsl:template>

	<xsl:template match="lem" mode="a">
		<term><xsl:apply-templates select="@*|node()" mode="#current"/></term>
	</xsl:template>

	<xsl:template match="text()" mode="a c">
		<xsl:sequence select="local:parse-breaks(.)"/>
	</xsl:template>

	<xsl:template match="level/text()" mode="a">
		<!--Get rid of leading and trailing spaces in notes-->
		<xsl:variable name="thisPos" select="position()"/>
		<xsl:choose>
			<xsl:when test="$thisPos=1 and last()=1">
				<xsl:value-of select="replace(.,'^\s+|\s+$','')"/>
			</xsl:when>
			<xsl:when test="$thisPos=last()">
				<xsl:value-of select="replace(.,'\s+$','')"/>
			</xsl:when>
			<xsl:when test="$thisPos=1">
				<xsl:value-of select="replace(.,'^\s+','')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

<!--Templates for collations-->

	<xsl:template match="coll" mode="c">
		<app>
			<xsl:copy-of select="local:appAtts(.)"/>
			<xsl:apply-templates mode="#current"/>
		</app>
	</xsl:template>

	<xsl:template match="lem" mode="c">
		<lem><xsl:apply-templates select="@*|node()" mode="#current"/></lem>
	</xsl:template>

	<xsl:template match="rdg" mode="c">
		<rdg>
			<xsl:apply-templates select="@*" mode="#current"/>
			<xsl:if test="@conj">
				<supplied evidence="conjectured"/>
			</xsl:if>
			<xsl:apply-templates select="node()" mode="#current"/>
		</rdg>
	</xsl:template>

	<xsl:template match="general_note | note" mode="c">
		<note><xsl:apply-templates mode="#current"/></note>
	</xsl:template>

	<xsl:template match="rdg/@resp" mode="c">
		<xsl:attribute name="wit">
			<xsl:value-of select="concat('wit:',.)"/>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="lem/@resp" mode="c">
		<xsl:attribute name="source"><xsl:value-of select="concat('wit:',.)"/></xsl:attribute>
	</xsl:template>

	<xsl:template match="@subst" mode="c">
		<xsl:attribute name="type" select="'substantive'"/>
	</xsl:template>

	<xsl:template match="@omit" mode="c"/> <!--Omit @omit, since it should mean the same as an empty elem-->

	<xsl:template match="@conj" mode="c"/> <!-- already handled in rdg template -->

<!-- Templates for both annotations and collations -->

	<xsl:template match="comment()" mode="a c">
		<xsl:copy-of select="."/>
	</xsl:template>

	<xsl:template match="ln" mode="a c"/> <!-- already handled by note/coll templates -->

	<xsl:template match="blockquote" mode="a c">
		<cit>
			<quote><xsl:apply-templates mode="#current"/></quote>
		</cit>
	</xsl:template>

	<xsl:template match="i" mode="a c">
		<hi rend="simple:italic"><xsl:apply-templates mode="#current"/></hi>
	</xsl:template>

	<xsl:template match="sup | sub" mode="a c">
		<hi rend="simple:{local-name()}"><xsl:apply-templates mode="#current"/></hi>
	</xsl:template>

	<xsl:template match="br" mode="a c">
		<lb/>
	</xsl:template>

	<xsl:template match="a" mode="a c">
		<xsl:variable name="href" select="
			if (contains(@href, ':/')) then @href
			else concat('http://', replace(@href, '^/+', ''))
		"/>
		<ref target="{$href}">
			<xsl:apply-templates mode="#current"/>
		</ref>
	</xsl:template>

	<!-- drop whitespace from top-level container elements -->
	<xsl:template mode="a" match="annotations/text() | note/text()"/>
	<xsl:template mode="c" match="collations/text() | coll/text()"/>

	<xsl:template match="*" mode="a c" priority="-1">
		<xsl:message>No templates matching <xsl:value-of select="local-name(.)"/></xsl:message>
	</xsl:template>

<!-- local support functions -->

	<!-- convert " . . . " to <gap/> and " / " to <lb/> -->
	<xsl:function name="local:parse-breaks" as="node()*">
		<xsl:param name="str" as="xs:string"/>
		<xsl:analyze-string select="$str" regex=" (\. \. \.|/)(( \. \. \.| /)*) ">
			<xsl:matching-substring>
				<xsl:text> </xsl:text>
				<xsl:choose>
					<xsl:when test="regex-group(1) = '/'"><lb/></xsl:when>
					<xsl:otherwise><gap/></xsl:otherwise>
				</xsl:choose>
				<xsl:choose>
					<xsl:when  test="regex-group(2) = ''">
						<xsl:text> </xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:sequence select="
							local:parse-breaks(
								concat(regex-group(2), ' ')
							)
						"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:matching-substring>
			<xsl:non-matching-substring>
				<xsl:value-of select="."/>
			</xsl:non-matching-substring>
		</xsl:analyze-string>
	</xsl:function>

	<!-- convert <ln/>'s to @from/@to pointers -->
	<xsl:function name="local:appAtts">
		<xsl:param name="el"/>
		<xsl:variable name="lnPointer" select="$el/ln"/>
		<xsl:variable name="lnNum" select="$lnPointer/@n | $lnPointer/@tln"/>
		<xsl:variable name="isRange" select="contains($lnNum, '-')"/>
		<xsl:choose>
			<xsl:when test="exists($el/@t) and $el/@t != 'tln'">
				<xsl:message terminate="yes">conversion can't handle non-TLN pointers</xsl:message>
			</xsl:when>
			<xsl:when test="contains($lnNum, ',')">
				<xsl:message terminate="yes">conversion can't handle multi-range matches</xsl:message>
			</xsl:when>
			<xsl:when test="$isRange">
				<xsl:variable name="tokens" select="tokenize($lnNum, '-')"/>
				<xsl:attribute name="from" select="concat('tln:', $tokens[1])"/>
				<xsl:attribute name="to" select="concat('tln:', $tokens[2])"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:attribute name="from" select="concat('tln:', $lnNum)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

</xsl:stylesheet>
