<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all"
    xpath-default-namespace=""
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:ise="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/text"
    xmlns:h="http://www.w3.org/1999/xhtml"
    xmlns:i="http://internetshakespeare.uvic.ca/#internal-linking"
    xmlns:hcmc="http://hcmc.uvic.ca/ns/1.0"
    xmlns:img="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/image.rng"
    xmlns:user="http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/schema/users"
    version="3.0">
    <xsl:import href="global.xsl"/>
    <xsl:include href="ilink.xsl"/>

    <xsl:variable name="uriRex" select="'^(.*/)?([^/_]+)_([^/]+)\.xml$'"/>
    <xsl:variable name="metadataDocFile" select="
        concat(
            $metadataPath,
            '/documents/doc_',
            replace(document-uri(), $uriRex, '$3.xml')
        )
    "/>
    <xsl:variable name="work" select="replace(document-uri(), $uriRex, '$2')"/>

    <xsl:variable name="date" select="format-date(current-date(),'[Y0001]-[M01]-[D01]')"/>
    <xsl:variable name="contentPath" select="'../../../eXist/db/apps/iseapp/content/'"/>
    <xsl:variable name="metadataDoc" select="doc($metadataDocFile)"/>
    <xsl:variable name="docId" select="replace(document-uri(), $uriRex, 'ise$3')"/>
    <xsl:variable name="docClass" select="for $n in tokenize($metadataDoc//ise:documentClass/text(),'\s+') return normalize-space($n)"/>



    <xsl:variable name="PERS1" select="$personography"/>
    <xsl:variable name="workIds" select="$taxonomies//taxonomy[@xml:id='iseWorks']/descendant::category/@xml:id"/>

    <xsl:output indent="yes" exclude-result-prefixes="#all" method="xml" encoding="UTF-8"/>

    <xsl:template match="/">
        <xsl:processing-instruction name="xml-model">href="../sch/ise.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction><xsl:text>&#x0a;</xsl:text>
        <xsl:processing-instruction name="xml-model">href="../sch/ise.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction><xsl:text>&#x0a;</xsl:text>
        <xsl:processing-instruction name="xml-model">href="../sch/ise.sch" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction><xsl:text>&#x0a;</xsl:text>
        <TEI>
            <xsl:attribute name="xml:id" select="$docId"/>
            <xsl:call-template name="createTeiHeader"/>
            <xsl:apply-templates/>
        </TEI>
    </xsl:template>


    <xsl:template match="content">
        <text>
            <body>
                <!--Is this the right way to do this? Not sure at the moment,
                    since there are inconsistencies with how divs are created. Sometimes
                    its by the header and sometimes it by divs...so, not sure exactly what to make
                    of this just yet-->
               <!-- <div>-->
                    <!--Perhaps it's easier to do this in passes...-->

             <xsl:variable name="docContent" as="element(tei:div)">
                 <!--There's an extra div here because headers are unpredictable-->
                 <div>
               <xsl:for-each-group select="*" group-starting-with="h1">
                   <div>
                            <xsl:if test="current-group()[1]/self::h1 and current-group()[1]/@id">
                                <xsl:attribute name="xml:id">
                                    <xsl:value-of select="replace(current-group()[1]/@id,':','_')"/>
                                </xsl:attribute>
                            </xsl:if>
                        <xsl:for-each-group select="current-group()" group-starting-with="h2">
                            <xsl:choose>
                                <xsl:when test="current-group()[1]/self::h2">
                                    <div>
                                        <xsl:if test="current-group()[1]/@id">
                                            <xsl:attribute name="xml:id">
                                                <xsl:value-of select="replace(current-group()[1]/@id,':','_')"/>
                                            </xsl:attribute>
                                        </xsl:if>
                                        <xsl:for-each-group select="current-group()" group-starting-with="h3">
                                           <xsl:choose>
                                               <xsl:when test="current-group()[1]/self::h3">
                                                <div>
                                                    <xsl:if test="current-group()[1]/@id">
                                                        <xsl:attribute name="xml:id">
                                                            <xsl:value-of select="replace(current-group()[1]/@id,':','_')"/>
                                                        </xsl:attribute>
                                                    </xsl:if>
                                                    <xsl:for-each-group select="current-group()" group-starting-with="h4">
                                                        <xsl:choose>
                                                            <xsl:when test="current-group()[1]/self::h4">
                                                                <div>
                                                                    <xsl:if test="current-group()[1]/@id">
                                                                        <xsl:attribute name="xml:id">
                                                                            <xsl:value-of select="replace(current-group()[1]/@id,':','_')"/>
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
                 </div>
                </xsl:variable>
                <xsl:copy-of select="hcmc:cutDivs($docContent)"/>
            </body>
        </text>
    </xsl:template>

    <!--Cut divs gets rid of container divs that are useless but difficult to
    mitigate in the ever-nesting for each groups above.-->
    <xsl:function name="hcmc:cutDivs">
        <xsl:param name="elem"/>
        <xsl:choose>
            <xsl:when test="$elem[self::tei:div][every $n in child::* satisfies local-name($n)='div']">
                <xsl:copy-of select="hcmc:cutDivs($elem/*)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$elem"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="h1| h2 |h3 |h4">
        <head>
            <xsl:apply-templates select="node()"/>
        </head>
    </xsl:template>

    <xsl:template match="div">
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

    <xsl:template match="div[@class='wikimodel-emptyline']">
        <!--This is weird formatting stuff but I don't think it really matters-->
        <lb/>
    </xsl:template>

    <!--Empty elements that have @ids-->
    <xsl:template match="div[@id][normalize-space(string-join(descendant::text()))=''] | span[@id] | a[normalize-space(string-join(descendant::text()))=''][@id]">
        <!--We turn these elements into anchors, but we change their ids. We will have to do a
            second sweep later where we investigate which divs/spans are being pointed to and create
            sensible xml:ids; once we've put @xml:ids on the correct elements, then we can go ahead
            and delete these anchors. This will cause some link-breakage in the wild, but I don't know
            if that can be mitigated.-->
        <anchor>
            <xsl:attribute name="n" select="@id"/>
        </anchor>
    </xsl:template>


    <xsl:template match="p">
        <p>
            <xsl:apply-templates select="@*|node()"/>
        </p>
    </xsl:template>

    <!--lb tags seem to be erroneously created when the em tag is used-->
    <!--So we only want to process lbs if they seem legitimate-->
    <xsl:template match="br | lb[not(ancestor::em)]">
        <lb/>
    </xsl:template>

    <!--These are useless-->
    <xsl:template match="lb[ancestor::em]"/>

    <xsl:template match="blockquote">
        <quote rend="block">
            <xsl:apply-templates/>
        </quote>
    </xsl:template>

    <xsl:template match="span[not(@id) and not(@class)]">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="ol|ul|dl">
           <xsl:choose>
               <xsl:when test="$docClass='bibliography'">
                   <listBibl>
                       <xsl:apply-templates select="node()"/>
                   </listBibl>
               </xsl:when>
               <xsl:otherwise>
                   <list type="{local-name()}">
                       <xsl:apply-templates select="node()"/>
                   </list>
               </xsl:otherwise>
           </xsl:choose>

    </xsl:template>



    <xsl:template match="li|dd">
        <xsl:choose>
            <xsl:when test="$docClass='bibliography'">
                <bibl><xsl:apply-templates select="node()"/></bibl>
            </xsl:when>
            <xsl:otherwise>
                <item><xsl:apply-templates select="node()"/></item>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="di">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="dt">
        <label><xsl:apply-templates/></label>
    </xsl:template>

   <!--Need tempaltes for ul and dl-->


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

    <!--Inline elements-->

    <!--First, footnotes-->
    <xsl:template match="sup[not(span[@class='footnoteRef'])]">
        <hi style="text-align:super;">
            <xsl:apply-templates/>
        </hi>
    </xsl:template>

    <xsl:template match="sup[span[@class='footnoteRef']]">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="span[@class='footnoteRef']">
        <xsl:variable name="thisFootnoteId" select="@id"/>
        <xsl:variable name="thisFn" select="//content/descendant::ol[@class='footnotes']/li[span/a[@href=concat('#',$thisFootnoteId)]]"/>
        <xsl:choose>
            <xsl:when test="$thisFn">
                <note><xsl:apply-templates select="$thisFn/node()"/></note>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>Footnote not found.</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--We don't need to process all of the content of the list item or
        the list of footnotes at the bottom-->
    <xsl:template match="ol[@class='footnotes'] |span[@class='xwikilink'][a[@class='footnoteBackRef']] |a[@class='footnoteBackRef']"/>



    <xsl:template match="em">
        <xsl:choose>
            <xsl:when test="$docClass='bibliography' and (ancestor::ol or ancestor::ul)">
                <title level="m"><xsl:apply-templates/></title>
            </xsl:when>
            <xsl:otherwise>
                <hi style="font-style:italic;">
                    <xsl:apply-templates/>
                </hi>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template match="strong">
        <hi style="font-weight:bold;">
            <xsl:apply-templates/>
        </hi>
    </xsl:template>

    <!--dels were being produced from weird escaping, but it is also used
        for a strike-out effect. Not sure if they are properly "del"s or not,
        so we'll flag them using a <hi>-->
    <xsl:template match="del">
        <hi rendition="simple:strikethrough"><xsl:apply-templates/></hi>
    </xsl:template>

    <!--Horizontal rules; I doubt they actually mean anything, but we'll leave 'em in just in case-->

    <xsl:template match="hr">
        <milestone unit="section" rend="horizontal-rule"/>
    </xsl:template>

    <xsl:template match="text">
        <xsl:value-of select="." disable-output-escaping="yes"/>
    </xsl:template>

<!--Linking-->

    <xsl:template match="span[@class='wikiinternallink']">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="span[@class='wikiexternallink']">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="a[@href]">
        <ref target="{@href}">
            <xsl:apply-templates/>
        </ref>
    </xsl:template>


<!--Functions-->

    <xsl:template name="createTeiHeader">
        <teiHeader>
            <fileDesc><titleStmt>
                <xsl:apply-templates select="$metadataDoc//ise:titles"/>
                <xsl:apply-templates select="$metadataDoc//ise:resp"/>
            </titleStmt>
                <publicationStmt copyOf="global:publicationStmt">
                    <publisher>Internet Shakespeare Editions</publisher>
                </publicationStmt>
                <sourceDesc>
                    <p>Born digital, but converted from XWiki.</p>
                </sourceDesc>
            </fileDesc>
            <xsl:variable name="docType" as="xs:string+">
                <xsl:for-each select="$docClass[not(.='')]">
                    <xsl:variable name="thisDocClass" select="."/>
                    <xsl:choose>
                        <xsl:when test="$thisDocClass='dramaticWork'">idtPrimary</xsl:when>
                        <xsl:otherwise>idtBornDigital</xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="$thisDocClass='bibliography'">idtParatextBibl</xsl:when>
                        <xsl:when test="$thisDocClass='chronology'">idtParatextChronology</xsl:when>
                        <xsl:when test="$thisDocClass='glossary'">idtParatextGloss</xsl:when>
                        <xsl:when test="$thisDocClass='characters'">idtParatextCharacters</xsl:when>
                        <xsl:when test="$thisDocClass='footnotes'">idtParatext</xsl:when>
                        <xsl:when test="$thisDocClass='teachingNotes'">idtParatextPedagogical</xsl:when>
                        <xsl:when test="$thisDocClass='genIntro'">idtParatextCritIntro</xsl:when>
                        <xsl:when test="$thisDocClass='criticalSurvey'">idtParatextHistCrit</xsl:when>
                        <xsl:when test="$thisDocClass='performanceHistory'">idtParatextHistPerf</xsl:when>
                        <xsl:when test="$thisDocClass='textualHistory'">idtParatextHistText</xsl:when>
                        <xsl:when test="$thisDocClass='dramaticWork'">idtParatext</xsl:when>
                        <xsl:otherwise>idtParatext</xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>

            </xsl:variable>
            <profileDesc>
                <textClass>
                    <xsl:if test="$work=$workIds">
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
            <revisionDesc>
                <change who="pers:TAKE1" when="{$date}">Created document.</change>
            </revisionDesc>
        </teiHeader>
    </xsl:template>

    <xsl:template match="ise:titles"  exclude-result-prefixes="#all">

        <xsl:apply-templates />

    </xsl:template>

    <xsl:template match="ise:titles/ise:title"  exclude-result-prefixes="#all">
        <title type="main"><xsl:apply-templates /></title>
    </xsl:template>

    <xsl:template match="ise:titles/ise:witness"  exclude-result-prefixes="#all">
        <xsl:comment>Can editions have witnesses?</xsl:comment>
        <title type="witness"><xsl:apply-templates /></title>
    </xsl:template>

    <xsl:template match="ise:titles/ise:mobileTitle"  exclude-result-prefixes="#all">
        <title type="short"><xsl:apply-templates /></title>
    </xsl:template>

    <!--Don't need the resp container in TEI-->
    <xsl:template match="ise:resp"  exclude-result-prefixes="#all">
        <xsl:apply-templates />
    </xsl:template>

    <!--Each agent gets their own respStmt-->
    <xsl:template match="ise:resp/ise:agent"  exclude-result-prefixes="#all">
        <xsl:variable name="thisAgent" select="."/>
        <xsl:variable name="thisPerson" select="$PERS1//(tei:person[@n=$thisAgent/@user]|tei:org[@n=$thisAgent/@user])"/>
        <xsl:variable name="keyVal" select="
            if (@role = 'owner') then 'copyright'
            else concat(@role,if (@class) then concat('|',@class) else ''
            )"/>
        <xsl:variable name="thisRespCat" select="$taxonomies//tei:category[some $n in tokenize(@n,',') satisfies $n=$keyVal]"/>
        <xsl:choose>
            <xsl:when test="exists($thisRespCat) and exists($thisPerson)">
                <respStmt>
                    <resp ref="resp:{$thisRespCat/@xml:id}"><xsl:value-of select="$thisRespCat/tei:catDesc/tei:term"/></resp>
                    <name ref="pers:{$thisPerson/@xml:id}"><xsl:value-of select="$thisPerson/tei:persName/tei:reg"/></name>
                </respStmt>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment><xsl:copy-of select="."/></xsl:comment>
                <xsl:message>Cannot find username or responsibility for this element:
                    <xsl:copy-of select="."/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*" priority="-1">
        <xsl:message>Element <xsl:value-of select="local-name()"/> not being processed. (<xsl:for-each select="@*">@<xsl:value-of select="local-name()"/>: <xsl:value-of select="."/><xsl:if test="not(last())">, </xsl:if></xsl:for-each>)</xsl:message>
    </xsl:template>

</xsl:stylesheet>
