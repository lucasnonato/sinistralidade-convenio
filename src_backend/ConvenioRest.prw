#INCLUDE 'protheus.ch'
#INCLUDE 'restful.ch'

WsRestful convenio Description "Serviços Rest dedicados a integrações padrões TOTVS Saúde Planos" Format APPLICATION_JSON

    WSDATA company as STRING OPTIONAL

    WSMETHOD GET companies DESCRIPTION "" ;
    WSsyntax "{apiVersion}/companies" ;
    PATH "{apiVersion}/companies" PRODUCES APPLICATION_JSON

    WSMETHOD GET lossRatio DESCRIPTION "" ;
    WSsyntax "{apiVersion}/lossRatio" ;
    PATH "{apiVersion}/lossRatio" PRODUCES APPLICATION_JSON

End WsRestful

WSMETHOD GET companies QUERYPARAM WSSERVICE convenio
local cSql      := ""
local cJson     := ""
local nX        := 1
local oJson     := JsonObject():new()

cSql := " SELECT BG9_CODIGO, BG9_DESCRI FROM " + retSqlName("BG9") + " BG9 "
cSql += " WHERE BG9_FILIAL = '" + xFilial("BG9") + "' "
cSql += " AND BG9.D_E_L_E_T_ = ' ' "
dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cSql),"TMPBG9",.F.,.T.)

oJson['items'] := {}

while !TMPBG9->(eof())
    aadd(oJson['items'], jsonObject():new())
    oJson['items'][nX]['code']         := TMPBG9->BG9_CODIGO
    oJson['items'][nX]['description']  := alltrim(TMPBG9->BG9_DESCRI)
    TMPBG9->(dbskip())
    nX++
enddo
TMPBG9->(dbclosearea())

cJson := fwJsonSerialize(oJson, .F., .F.)
::setResponse(cJson)

Return .T.

WSMETHOD GET lossRatio QUERYPARAM company WSSERVICE convenio
local cSql      := ""
local cJson     := ""
local nX        := 1
local nVlrTot   := 0
local oJson     := JsonObject():new()

cSql += " SELECT  "
cSql += " CASE  "
cSql += "       WHEN BJE_DESCRI IS NULL then 'INTERNACAO' "
cSql += "       ELSE BJE_DESCRI end as DESCRI "
cSql += " , SUM(BD6_VLRPAG) VLR FROM " + retSqlName("BD6") + " BD6 "
cSql += " INNER JOIN " + retSqlName("BR8") + " BR8 "
cSql += " ON BR8_FILIAL = '" + xFilial("BR8") + "' "
cSql += " AND BR8_CODPAD = BD6_CODPAD "
cSql += " AND BR8_CODPSA = BD6_CODPRO "
cSql += " AND BR8.D_E_L_E_T_ = ' ' "
cSql += " LEFT JOIN " + retSqlName("BJE") + " BJE "
cSql += " ON BJE_FILIAL = '" + xFilial("BJE") + "' "
cSql += " AND BJE_CODIGO = BR8_CLASSE "
cSql += " AND BJE.D_E_L_E_T_ = ' ' "
cSql += " WHERE BD6_FILIAL = '" + xFilial("BD6") + "' "
cSql += " AND BD6_CODEMP = '" + ::company + "' "
cSql += " AND BD6.D_E_L_E_T_ = ' ' "
cSql += " GROUP BY BJE_DESCRI "
cSql += " ORDER BY VLR DESC "
dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cSql),"TMPBJE",.F.,.T.) 

oJson['items'] := {}

while !TMPBJE->(eof())
    nVlrTot += TMPBJE->VLR
    aadd(oJson['items'], jsonObject():new())
    oJson['items'][nX]['value']        := TMPBJE->VLR
    oJson['items'][nX]['description']  := alltrim(TMPBJE->DESCRI)
    TMPBJE->(dbskip())
    nX++
enddo
TMPBJE->(dbclosearea())

oJson['totalValue']     := nVlrTot
oJson['agreedValue']    := nVlrTot + Randomize( nVlrTot/4, nVlrTot )

cJson := fwJsonSerialize(oJson, .F., .F.)
::setResponse(cJson)

Return .T.

