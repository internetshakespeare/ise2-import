<!-- converts an ISE2 facsimile "copy" into TEI -->
<xsl:stylesheet version="3.0"
	xmlns="http://www.tei-c.org/ns/1.0"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"

	xmlns:f="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/text"
	xmlns:r="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/reference.rng"
	xmlns:c="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/country.rng"
	xmlns:g="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/image.rng"

	xmlns:meta="http://ise3.uvic.ca/ns/ise2-import/metadata"
	xmlns:util="http://ise3.uvic.ca/ns/ise2-import/util"

	exclude-result-prefixes="#all"
	xpath-default-namespace=""
>
	<xsl:import href="global.xsl"/>

	<xsl:output indent="yes"/>

	<xsl:variable name="pubRef" select="//f:publication[@rel='identity']"/>
	<xsl:variable name="publication" select="meta:publication($pubRef/@ref)/*"/>
	<xsl:variable name="volume" select="
		if ($pubRef/r:anchor[@type='volume'])
		then id($pubRef/r:anchor[@type='volume']/@name, $publication)
		else $publication/descendant::f:volume[1]
	"/>
	<xsl:variable name="allHeads" as="node()*" select="/f:copy/f:head, $volume, $publication/f:head"/>

	<xsl:template match="/">
		<xsl:if test="empty(f:copy)">
			<xsl:message terminate="yes">This transform is intended to be run on an ISE2 "copy" document.</xsl:message>
		</xsl:if>
		<xsl:if test="empty($volume)">
			<xsl:message terminate="yes">Can't find metadata for volume.</xsl:message>
		</xsl:if>
		<xsl:sequence select="util:xml-model(concat('../sch/', $site, '.rng'))"/>
		<xsl:sequence select="util:xml-model(concat('../sch/', $site, '.sch'))"/>
		<xsl:apply-templates select="f:copy"/>
	</xsl:template>

	<xsl:template match="f:copy">
		<TEI version="5.0">
			<xsl:copy-of select="@xml:id"/>
			<xsl:apply-templates/>
		</TEI>
	</xsl:template>

	<xsl:template match="f:head">
		<teiHeader>
			<fileDesc>
				<xsl:if test="f:description">
					<xsl:comment>
						FIXME: figure out what to do with this description of the copy:

						<xsl:value-of select="f:description"/>
					</xsl:comment>
				</xsl:if>
				<titleStmt>
					<xsl:apply-templates mode="meta:titles" select="($allHeads/f:titles/f:title)[1]"/>
					<xsl:apply-templates mode="meta:titles" select="($allHeads/f:titles/f:subTitle)[1]"/>
					<xsl:apply-templates mode="meta:titles" select="($allHeads/f:titles/f:witness)[1]"/>
					<xsl:apply-templates mode="meta:titles" select="($allHeads/f:titles/f:mobileTitle)[1]"/>
					<xsl:apply-templates mode="meta:titles" select="($allHeads/f:titles/f:longTitle)[1]"/>
					<respStmt>
						<resp ref="resp:edt_mrk">Encoder</resp>
						<name ref="pers:TERP1">Maxwell Terpstra</name>
					</respStmt>
				</titleStmt>
				<publicationStmt next="global:publicationStmt">
					<xsl:apply-templates select="f:rights"/>
				</publicationStmt>
				<sourceDesc>
					<xsl:apply-templates select="." mode="bibl"/>
					<msDesc>
						<xsl:apply-templates select="." mode="msIdentifier"/>
						<msContents>
							<xsl:apply-templates select="$volume//f:workMap" mode="msContents"/>
						</msContents>
						<physDesc>
							<xsl:apply-templates select="//f:manuscript" mode="physDesc"/>
							<objectDesc>
								<xsl:apply-templates select="//f:scannedFrom"/>
								<xsl:apply-templates select="$publication//f:pageGathering"/>
							</objectDesc>
						</physDesc>
					</msDesc>
				</sourceDesc>
			</fileDesc>
			<profileDesc>
				<textClass>
					<xsl:apply-templates select="$volume//f:workMap" mode="textClass"/>
					<xsl:apply-templates select="//f:manuscript" mode="textClass"/>
					<xsl:call-template name="facsimile-category"/>
				</textClass>
			</profileDesc>
			<encodingDesc>
				<listPrefixDef>
					<prefixDef ident="src" matchPattern="(.+)" replacementPattern="file://home1t/iseadmin/ise3/facsimiles/{/f:copy/@xml:id}/$1">
						<p>High-quality archival scan file, stored on the SAN.</p>
					</prefixDef>
				</listPrefixDef>
				<listPrefixDef copyOf="global:listPrefixDef"/>
				<projectDesc copyOf="global:projectDesc"/>
				<editorialDecl copyOf="global:editorialDecl_facsimile"/>
			</encodingDesc>
			<revisionDesc status="converted">
				<xsl:sequence select="util:conversion-change()"/>
			</revisionDesc>
		</teiHeader>
	</xsl:template>

	<xsl:template match="f:head" mode="bibl">
		<biblStruct>
			<xsl:comment>FIXME: replace with a bibl[@copyOf] pointing at BIBL1.xml</xsl:comment>
			<xsl:variable name="published" select="$allHeads//f:subjectPublished"/>
			<monogr>
				<title><xsl:value-of select="($allHeads//f:title)[1]"/></title>
				<xsl:for-each select="$published/@ISBN">
					<idno type="ISBN"><xsl:value-of select="."/></idno>
				</xsl:for-each>
				<xsl:for-each select="$published/@ISSN">
					<idno type="ISSN"><xsl:value-of select="."/></idno>
				</xsl:for-each>
				<xsl:for-each select="$published/@uri">
					<idno type="URI"><xsl:value-of select="."/></idno>
				</xsl:for-each>
				<xsl:if test="$publication//f:registered">
					<availability>
						<licence>
							<xsl:copy-of select="$publication//f:registered/@*"/>
							<xsl:text>Recorded in the stationer's register.</xsl:text>
						</licence>
					</availability>
				</xsl:if>
				<imprint>
					<xsl:for-each select="$published/f:publisher">
						<publisher>
							<xsl:choose>
								<xsl:when test="@user">
									<xsl:value-of select="util:name-for-user(@user)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="."/>
								</xsl:otherwise>
							</xsl:choose>
						</publisher>
					</xsl:for-each>
					<xsl:where-populated>
						<pubPlace>
							<xsl:where-populated>
								<settlement><xsl:value-of select="$published/f:city"/></settlement>
							</xsl:where-populated>
							<xsl:where-populated>
								<country><xsl:value-of select="$published/c:country"/></country>
							</xsl:where-populated>
						</pubPlace>
					</xsl:where-populated>
					<xsl:where-populated>
						<date>
							<xsl:copy-of select="$published/(@when, @notAfter, @notBefore, @cert)"/>
							<xsl:value-of select="($published/(@when, @notAfter, @notBefore))[1]"/>
						</date>
					</xsl:where-populated>
					<xsl:if test="$allHeads/f:agent[@role='printer']/@user">
						<respStmt>
							<resp ref="resp:ptr">Printer</resp>
							<xsl:sequence select="util:name-for-user(
								($allHeads/f:agent[@role='printer']/@user)[1]
							)"/>
						</respStmt>
					</xsl:if>
					<xsl:if test="$allHeads/f:agent[@role='bookseller']/@user">
						<respStmt>
							<resp ref="resp:bsl">Bookseller</resp>
							<xsl:sequence select="util:name-for-user(
								($allHeads/f:agent[@role='printer']/@user)[1]
							)"/>
						</respStmt>
					</xsl:if>
					<xsl:if test="$publication/f:head/f:description">
						<xsl:comment>
							FIXME: decide what to do with this description of the publication:

							<xsl:value-of select="$publication/f:head/f:description"/>
						</xsl:comment>
					</xsl:if>
					<!-- note: no volume descriptions currently in use -->
				</imprint>
			</monogr>
		</biblStruct>
	</xsl:template>

	<xsl:template match="f:head" mode="msIdentifier">
		<msIdentifier>
			<xsl:variable name="authority" as="item()">
				<xsl:choose>
					<xsl:when test=".//f:id[@type='call_number']/@user">
						<xsl:sequence select="util:name-for-user(.//f:id[@type='call_number']/@user)"/>
					</xsl:when>
					<!-- note: all current cases where @authority is used, owner agent is better -->
					<xsl:when test=".//f:agent[@role='owner']/@user">
						<xsl:sequence select="util:name-for-user(.//f:agent[@role='owner']/@user)"/>
					</xsl:when>
					<xsl:when test=".//f:agent[@role='owner']">
						<xsl:value-of select=".//f:agent[@role='owner']"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>Unknown</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$authority instance of element(tei:persName)">
					<xsl:message terminate="yes">unexpected person (instead of org) owning facsimile</xsl:message>
				</xsl:when>
				<xsl:when test="$authority instance of element(tei:orgName)">
					<xsl:variable name="orgId" select="substring-after($authority/@ref, 'org:')"/>
					<xsl:variable name="parent" select="id($orgId, $orgography)/parent::tei:org"/>
					<xsl:if test="exists($parent)">
						<institution ref="concat('org:', $parent/@xml:id)">
							<xsl:value-of select="$authority"/>
						</institution>
					</xsl:if>
					<repository ref="{$authority/@ref}">
						<xsl:value-of select="$authority"/>
					</repository>
				</xsl:when>
				<xsl:otherwise>
					<xsl:comment>FIXME: this should use an orgography reference</xsl:comment>
					<repository><xsl:value-of select="$authority"/></repository>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test=".//f:id[@type='call_number']">
				<idno><xsl:value-of select="(.//f:id[@type='call_number'])[1]"/></idno>
			</xsl:if>
			<xsl:comment>FIXME: make sure this isn't just the name of the library</xsl:comment>
			<msName><xsl:value-of select="($allHeads//f:witness)[1]"/></msName>
		</msIdentifier>
	</xsl:template>

	<xsl:template match="f:rights">
		<authority>
			<xsl:choose>
				<xsl:when test="//f:agent[@role='owner']/@user">
					<xsl:sequence select="util:name-for-user(//f:agent[@role='owner']/@user)"/>
				</xsl:when>
				<xsl:when test="//f:agent[@role='owner']/node()">
					<xsl:comment>FIXME: this should be a orgography reference</xsl:comment>
					<xsl:apply-templates select="//f:agent[@role='owner']/node()"/>
				</xsl:when>
				<xsl:when test="node()">
					<xsl:comment>FIXME: this should be a orgography reference</xsl:comment>
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:comment>FIXME: who is this?</xsl:comment>
					<xsl:text>Image provider</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</authority>
		<availability>
			<p>
				<xsl:choose>
					<xsl:when test="@license = 'ISE-Image:1'">Included images are protected by copyright. They may be freely used for educational, non-profit purposes. All other uses must be negotiated with the copyright holder.</xsl:when>
					<xsl:when test="@license = 'rights-reserved:1'">Included images are protected by copyright.</xsl:when>
					<xsl:when test="@license">
						<xsl:message terminate="yes" expand-text="yes">Unexpected facsimile license type {@license}</xsl:message>
					</xsl:when>
					<xsl:otherwise>Included images are protected by copyright.</xsl:otherwise>
				</xsl:choose>
			</p>
		</availability>
	</xsl:template>

	<xsl:template match="f:manuscript" mode="physDesc">
		<xsl:if test=". = 'true'">
			<scriptDesc>
				<p>Manuscript.</p>
			</scriptDesc>
		</xsl:if>
	</xsl:template>
	<xsl:template match="f:manuscript" mode="textClass">
		<xsl:if test=". = 'true'">
			<!-- FIXME: won't work for DRE/QME? -->
			<catRef scheme="idt:iseDocumentTypes" target="idt:idtFacsimileManuscript"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="f:pageGathering">
		<!-- FIXME: ask JJ if we want to do more with this? -->
		<p>
			<xsl:value-of select="concat(
				upper-case(substring(., 1, 1)),
				substring(., 2)
			)"/>
			<xsl:text>.</xsl:text>
		</p>
	</xsl:template>

	<xsl:template match="f:scannedFrom">
		<xsl:choose>
			<xsl:when test=". = 'facsimile'"><p>Facsimile.</p></xsl:when>
			<xsl:when test=". = 'microform'"><p>Microform.</p></xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="f:workMap" mode="textClass">
		<xsl:sequence select="util:catRef-for-work(f:work/@ref)"/>
	</xsl:template>

	<xsl:template match="f:workMap" mode="msContents">
		<xsl:variable name="work" select="util:category-for-work(f:work/@ref)"/>
		<msItem class="idt:{$work/parent::tei:taxonomy/@xml:id}" corresp="idt:{$work/@xml:id}">
			<locus from="{@start-page}" to="{@end-page}"/>
			<title><xsl:value-of select="$work/tei:catDesc"/></title>
		</msItem>
	</xsl:template>

	<xsl:template name="facsimile-category">
		<!-- FIXME: won't work for DRE/QME? -->
		<catRef scheme="idt:iseDocumentTypes">
			<xsl:attribute name="target">
				<xsl:choose>
					<xsl:when test="$publication/@xml:id = 'pub_F1'">idt:idtFacsimileFOLI1</xsl:when>
					<xsl:when test="$publication/@xml:id = 'pub_F2'">idt:idtFacsimileFOLI2</xsl:when>
					<xsl:when test="$publication/@xml:id = 'pub_F3'">idt:idtFacsimileFOLI3</xsl:when>
					<xsl:when test="$publication/@xml:id = 'pub_F4'">idt:idtFacsimileFOLI4</xsl:when>
					<xsl:when test="$publication//f:pageGathering = 'folio'">idt:idtFacsimileFolio</xsl:when>
					<xsl:when test="$publication//f:pageGathering = 'quarto'">idt:idtFacsimileQuarto</xsl:when>
					<xsl:when test="$publication//f:pageGathering = 'octavo'">idt:idtFacsimileOctavo</xsl:when>
					<xsl:otherwise>idt:idtFacsimile</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
		</catRef>
	</xsl:template>

	<xsl:template match="f:content">
		<sourceDoc>
			<xsl:comment>FIXME: check that milestone/@unit are correct</xsl:comment>
			<xsl:variable name="copy" select="/"/>
			<xsl:variable name="thumb" select="/f:copy/f:head/f:thumbnail/g:*"/>
			<xsl:merge>
				<xsl:merge-source select="$copy//f:page" sort-before-merge="yes">
					<xsl:merge-key select="number(@n)"/>
				</xsl:merge-source>
				<xsl:merge-source name="pub" select="$volume//f:page" sort-before-merge="yes">
					<xsl:merge-key select="number(@n)"/>
				</xsl:merge-source>
				<xsl:merge-action>
					<xsl:variable name="pageNum" select="current-merge-key()"/>
					<surface n="{$pageNum}">
						<xsl:if test="g:*/@href = $thumb/@href">
							<!-- mark this page as representative for thumbnails -->
							<anchor xml:id="thumbpage"/>
						</xsl:if>
						<pb>
							<xsl:if test="current-merge-group('pub')/@signature">
								<xsl:attribute name="n" select="current-merge-group('pub')/@signature"/>
							</xsl:if>
						</pb>
						<xsl:for-each select="$volume//f:section[@start-page = $pageNum]">
							<milestone unit="scene" n="{@name}"
								corresp="idt:{util:category-for-work(parent::*/f:work/@ref)/@xml:id}"/>
						</xsl:for-each>
						<xsl:for-each select="$volume//f:lineation[@page = $pageNum]">
							<fs type="lineation"
								corresp="idt:{util:category-for-work(parent::*/f:work/@ref)/@xml:id}">
								<f name="{@type}"><numeric value="{@from}" max="{@to}"/></f>
							</fs>
						</xsl:for-each>
						<xsl:for-each select="g:source">
							<graphic url="src:{replace(@href, '^.*/', '')}">
								<xsl:sequence select="util:infer-filetype(@href)"/>
							</graphic>
						</xsl:for-each>
						<xsl:if test="@missing = 'true'">
							<note>Missing page.</note>
						</xsl:if>
						<xsl:if test="current-merge-group('pub')/@blank = 'true'">
							<note>Blank page.</note>
						</xsl:if>
						<xsl:for-each select="current-merge-group()/f:comment">
							<note><xsl:value-of select="."/></note>
						</xsl:for-each>
					</surface>
				</xsl:merge-action>
			</xsl:merge>
		</sourceDoc>
	</xsl:template>

</xsl:stylesheet>
