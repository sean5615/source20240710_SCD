<%/*
----------------------------------------------------------------------------------
File Name		: scd018m_01v1
Author			: 黎岩慶
Description		: SCD018M_查詢當學期成績 - 顯示頁面
Modification Log	:

Vers		Date       	By            	Notes
--------------	--------------	--------------	----------------------------------
0.0.2       096/05/15   WEN         依SPEC重新修改
                                    1.Table欄位
                                    2.改成DAO的格式
                                    3.修改整個匯出的方式
0.0.1		096/03/13	黎岩慶    	Code Generate Create
0.0.3		096/09/25	poto    	修改拿掉校本部 和排序科目
0.0.4		096/10/01	poto    	科目+distinct
----------------------------------------------------------------------------------
*/%>
<%@ page contentType="text/html; charset=UTF-8" errorPage="/utility/errorpage.jsp" pageEncoding="MS950"%>
<%@ include file="/utility/header.jsp"%>
<%@ include file="/utility/viewpagedbinit.jsp"%>
<%@ page import="java.util.* , com.nou.sys.dao.*"%>
<jsp:useBean id="AUTGETRANGE" scope="session" class="com.nou.aut.AUTGETRANGE" />

<%
	/**取得學年期資料*/
	String QQ="";//身分註記
	DBManager dbManager = null;
	Connection con = null;
	DBResult rs = null;
	String s = null;
	String sms = null;
	String sms_cht = null;
	String date = DateUtil.getNowTimeMs();
	try {
		dbManager = new DBManager(logger);
		com.nou.scd.bo.SCDGETSMSDATA sysgetsmsdata = new com.nou.scd.bo.SCDGETSMSDATA(dbManager);		
		sysgetsmsdata.setSYS_DATE(DateUtil.getNowDate());
		sysgetsmsdata.setSMS_TYPE("1");
		int rtn = sysgetsmsdata.execute();
		s = sysgetsmsdata.getAYEAR();
		sms = sysgetsmsdata.getSMS();
		con		=	dbManager.getConnection(AUTCONNECT.mapConnect("SCD", session));
       	rs			=	dbManager.getSimpleResultSet(con);
        rs.open();

        SYST001DAO syst001Dao = new SYST001DAO(dbManager,con);
		syst001Dao.setResultColumn("CODE, CODE_NAME");
		syst001Dao.setWhere("KIND = 'SMS' AND CODE IN (" + sms + ")");
        rs =  syst001Dao.query();
        if(rs.next()){
          sms_cht = 		rs.getString("CODE_NAME");
        }
	} finally {
		if (rs != null) rs.close();
		if (dbManager != null) dbManager.close();
	}

	String ID_TYPE = (String)session.getAttribute("ID_TYPE");
	String PRVLG_TYPE = "";	//中心或是全校
	String stno = null;
	String idno = "";
	String CENTER_CODE = null;
	Vector dep = null;
	String disabled= null;
	StringBuffer sql = new StringBuffer();
	dep = AUTGETRANGE.getDEP_CODE("3","3");		//權限別(PRVLG_TP[3.全校])、身份別(ID_TP[3.行政人員])
	if(dep.size()>0){							//權限別(PRVLG_TP[4.中心])、身份別(ID_TP[3.行政人員])
		PRVLG_TYPE ="3";
		stno="";
		QQ = "511";
	}else if(ID_TYPE.equals("2")){				//權限別(PRVLG_TP[1.個別])、身份別(ID_TP[2.教師])
		PRVLG_TYPE ="1";
		stno="";
		dep = AUTGETRANGE.getDEP_CODE("1","2");
		if(dep.size()>0){
			stno="";
			CENTER_CODE = getDepStr(dep);
		}
	}else if(ID_TYPE.equals("1")){				//權限別(PRVLG_TP[1.個別])、身份別(ID_TP[1.學生])
		dep = AUTGETRANGE.getDEP_CODE("1","1");		
		PRVLG_TYPE ="1";
		if(dep.size()>0){
			CENTER_CODE = getDepStr(dep);
			dbManager = new DBManager(logger);
			com.nou.stu.STUGETSTNO STNO = new com.nou.stu.STUGETSTNO(dbManager);
			String user_name = (String )session.getAttribute("USER_NAME");
			idno = (String)session.getAttribute("USER_IDNO");
			STNO.setIDNO(idno);
			STNO.setASYS(sms);
			STNO.setBIRTHDATE("");
			STNO.setNAME(user_name);
			int rtn = STNO.execute();
			java.util.Vector stnos = STNO.getSTNO();
			if(stnos.size()>0){
				stno =stnos.get(0).toString();
			}else{
				stno="";
			}
			disabled = "readonly";
		}
	}else{
		PRVLG_TYPE ="4";
		 //權限別(PRVLG_TP[4.中心])、身份別(ID_TP[3.行政人員])
		stno="";
		dep = AUTGETRANGE.getDEP_CODE("4","3");
		CENTER_CODE = getDepStr(dep);
	}
	/**取得中心別 */
	sql.append("NOU#");
	sql.append(" SELECT A.CODE AS SELECT_VALUE,A.CODE_NAME AS SELECT_TEXT ");
	sql.append(" FROM SYST001 A ");
	sql.append(" WHERE A.KIND = 'CENTER_CODE' ");
	if (CENTER_CODE != null)sql.append(" AND A.CODE IN (").append(CENTER_CODE).append(")");
	sql.append(" AND A.CODE!= '00' ");// by poto
	sql.append(" ORDER BY  A.CODE ");
	session.setAttribute("scd018M_01_SELECT", sql.toString());

	/**取得科目名稱*/
	sql.setLength(0);
	sql.append("NOU#");
   sql.append("SELECT A.CRSNO, B.CRS_NAME ");
   sql.append("FROM ( ");
   if("1".equals(ID_TYPE)) { //學生
      sql.append("SELECT distinct CRSNO ");//by poto 不要讓科目重複
      sql.append("FROM PLAT007 ");
      sql.append(" WHERE AYEAR = '[AYEAR]' AND SMS = '[SMS]'");
      sql.append("AND STNO = '" + stno + "' ");
   } else if("2".equals(ID_TYPE)){ //老師
      sql.append("SELECT distinct a.CRSNO ");
      sql.append("FROM PLAT012 a ");
	  sql.append("JOIN REGT007 C ON A.AYEAR=C.AYEAR AND A.SMS=C.SMS AND A.CRSNO=C.CRSNO AND A.CLASS_CODE=C.ASS_CLASS_CODE ");	  
      sql.append("WHERE a.AYEAR = '[AYEAR]' AND a.SMS = '[SMS]' ");	  
      sql.append("AND a.TCH_IDNO = '" + session.getAttribute("USER_IDNO") + "' ");
   } else { //中心
      sql.append("SELECT distinct CRSNO ");
      sql.append("FROM PLAT012 ");
      sql.append(" WHERE AYEAR = '[AYEAR]' AND SMS = '[SMS]'");
      sql.append("AND CENTER_ABRCODE = (SELECT CENTER_ABRCODE FROM SYST002 WHERE CENTER_CODE = '[CENTER_CODE]') ");
      //sql.append("AND TCH_IDNO = '" + session.getAttribute("USER_IDNO") + "' ");
   }
   
   sql.append(")A, COUT002 B ");
   sql.append("WHERE A.CRSNO = B.CRSNO ORDER BY CRSNO");//by poto

   session.setAttribute("scd018m_01_WINDOW", sql.toString());
   session.setAttribute("scd018m_01_BLUR","NOU#SELECT CRSNO, CRS_NAME FROM COUT002 WHERE CRSNO = '[CRSNO]' ORDER BY CRSNO "); //by poto

	/**取得班級*/
	String TCH_IDNO = "";
	sql.setLength(0);
	sql.append("NOU#");	
	if(ID_TYPE.equals("2")){ //身分別為教師
		sql.append(" SELECT DISTINCT CLASS_CODE AS SELECT_TEXT, CLASS_CODE AS SELECT_VALUE ");
		sql.append(" FROM PLAT012 A");
		sql.append(" JOIN REGT007 C ON A.AYEAR=C.AYEAR AND A.SMS=C.SMS AND A.CRSNO=C.CRSNO AND A.CLASS_CODE=C.ASS_CLASS_CODE ");
		sql.append(" JOIN SYST002 B ON A.CENTER_ABRCODE = B.CENTER_ABRCODE ");		
		sql.append(" WHERE A.AYEAR = '[AYEAR]' AND A.SMS = '[SMS]'");
		sql.append(" AND A.TCH_IDNO =  '").append((String)session.getAttribute("USER_IDNO")).append("'");
		//sql.append(" AND B.CENTER_CODE = '[CENTER_CODE]' ");
		sql.append(" AND A.CRSNO = '[CRSNO]' ");		
		sql.append(" ORDER BY CLASS_CODE ");
		session.setAttribute("SCD018M_01_DYNSELECT", sql.toString());
		TCH_IDNO = (String)session.getAttribute("USER_IDNO");
	}else if(ID_TYPE.equals("1")){//身分別為學生
		sql.append(" SELECT DISTINCT A.TUT_CLASS_CODE AS SELECT_TEXT, A.TUT_CLASS_CODE AS SELECT_VALUE ");
		sql.append(" FROM PLAT007 A, ");
		sql.append("	( SELECT CENTER_ABRCODE FROM SYST002 WHERE CENTER_CODE = '[CENTER_CODE]') S ");
		sql.append(" WHERE A.AYEAR = '[AYEAR]' AND A.SMS = '[SMS]'");
		sql.append(" AND A.CENTER_ABRCODE = S.CENTER_ABRCODE");
		sql.append(" AND STNO = '").append(stno).append("'");
		session.setAttribute("SCD018M_01_DYNSELECT", sql.toString());
	}else{					//中心
		sql.append(" SELECT DISTINCT A.CLASS_CODE AS SELECT_TEXT,A.CLASS_CODE AS SELECT_VALUE ");
		sql.append(" FROM PLAT012 A ");
		sql.append(" JOIN SYST002 B ON A.CENTER_ABRCODE = B.CENTER_ABRCODE ");		
		sql.append(" WHERE A.AYEAR = '[AYEAR]' AND A.SMS = '[SMS]'");
		sql.append(" AND B.CENTER_CODE = '[CENTER_CODE]' ");
		sql.append(" AND A.CRSNO = '[CRSNO]' ");
		sql.append(" AND A.CLASS_KIND != '2' ");
		sql.append(" ORDER BY A.CLASS_CODE ");
		session.setAttribute("SCD018M_01_DYNSELECT", sql.toString());
	}
%>
<%!
	private String getDepStr(Vector dep) {
		StringBuffer CENTER_CODE = new StringBuffer();
		for (int i=0;i<dep.size();i++) {
            if(CENTER_CODE.length() > 0) {
                CENTER_CODE.append(",");
            }
            CENTER_CODE.append("'" + dep.get(i) +"'");
		}
		if (CENTER_CODE.length() == 0) {
			CENTER_CODE.append("''");
		}
        return CENTER_CODE.toString();
   }
%>
<html>
<head>
	<script src="<%=vr%>script/framework/query1_1_0_2.jsp"></script>
	<script src="scd018m_01c1.jsp"></script>
	<noscript>
		<p>您的瀏覽器不支援JavaScript語法，但是並不影響您獲取本網站的內容</p>
	</noscript>
</head>
<body background="<%=vr%>images/ap_index_bg.jpg" alt="背景圖" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" >

<!-- 定義查詢的 Form 起始 -->
<form name="QUERY" method="post" onsubmit="doQuery(<%=s%>,<%=sms%>);" style="margin:0,0,5,0;">
	<input type=hidden name="control_type">
	<input type=hidden name="pageSize">
	<input type=hidden name="pageNo">
	<input type=hidden name="EXPORT_FILE_NAME">
	<input type=hidden name="EXPORT_COLUMN_FILTER">
	<input type=hidden name="Date" value="<%=date%>">
	<input type=hidden name="CRD">
	<input type=hidden name="GMARK1">
	<input type=hidden name="GMARK2">
	<input type=hidden name="GMARK3">
	<input type=hidden name="GMARK_AVG">
	<input type=hidden name="MIDMARK">
	<input type=hidden name="FNLMARK">
	<input type=hidden name="RMK1">
	<input type=hidden name="AYEAR_SCD">
	<input type=hidden name="SMS_SCD">
	<input type=hidden name="TCH_IDNO" value='<%=TCH_IDNO%>'>	
	<input type=hidden name="QQ" value='<%=QQ%>'  ><!--註冊組人員-->


	<!-- 查詢全畫面起始 -->
	<TABLE id="QUERY_DIV" width="96%" border="0" align="center" cellpadding="0" cellspacing="0" summary="排版用表格">
		<tr>
			<td width="13"><img src="<%=vr%>images/ap_search_01.jpg" alt="排版用圖示" width="13" height="12"></td>
			<td width="100%"><img src="<%=vr%>images/ap_search_02.jpg" alt="排版用圖示" width="100%" height="12"></td>
			<td width="13"><img src="<%=vr%>images/ap_search_03.jpg" alt="排版用圖示" width="13" height="12"></td>
		</tr>
		<tr>
			<td width="13" background="<%=vr%>images/ap_search_04.jpg" alt="排版用圖示">&nbsp;</td>
			<td width="100%" valign="top" bgcolor="#C5E2C3">
				<!-- 按鈕畫面起始 -->
				<table width="100%" border="0" align="center" cellpadding="2" cellspacing="0" summary="排版用表格">
					<tr class="mtbGreenBg">
						<td align=left>【查詢畫面】</td>
						<td align=right>
							<div id="serach_btn">
								<input type=button class="btn" value='清  除' onkeypress="doReset();"onclick="doReset();">
								<input type=submit class="btn" value='查  詢' name='QUERY_BTN'>
								<input type=button class="btn" value='列  印' name="PRT_ALL_BTN" onkeypress="doPrint('QUERY');"onclick="doPrint('QUERY');">
								<% if(PRVLG_TYPE.equals("3")) {%>
									<input type=button class="btn" value='匯  出' name="EXPORT_ALL_BTN" onkeypress="doExport();"onclick="doExport();" >								
								<%}else{%>
									<input type=button class="btn" value='匯  出' name="EXPORT_ALL_BTN" onkeypress="doExport();"onclick="doExport();" disabled>								
								<%}%>
							</div>
						</td>
					</tr>
				</table>
				<!-- 按鈕畫面結束 -->

				<!-- 查詢畫面起始 -->
				<table id="table1" width="100%" border="0" align="center" cellpadding="2" cellspacing="1" summary="排版用表格">
					<tr>
						<td align='right'>學年期<font color=red>＊</font>：</td>
						<td>
							<input type='text' name='AYEAR' Column='AYEAR' onchange= 'setDynSelect();'>							
							<select name='SMS'onchange='setDynSelect();'>
								<option>請選擇</option>
								<script>Form.getSelectFromPhrase("SYST001_01_SELECT", "KIND", "SMS");</script>
							</select>				
						</td>					
						<% if(ID_TYPE.equals("2")) {%>
						<td>
							<input type=hidden name="CENTER_CODE" value="">
						</td>
						<td>
						</td>
						<% } else {%>
						<td align='right'>中心別<font color=red>＊</font>：</td>
						<td>
							<select name='CENTER_CODE' Column='CENTER_CODE'>
								<% if((ID_TYPE.equals("3")||ID_TYPE.equals("7"))&&"3".equals(PRVLG_TYPE)) {%>
								<option value=''>請選擇</option>
								<% } %>
								<script>Form.getSelectFromPhrase("scd018M_01_SELECT", "", "");</script>
							</select>
						</td>
						<% } %>
					</tr>

					<tr>  
						<td align='right'>科目：</td>
						<td>
							<input type='text' size='5' Column='CRSNO' name='CRSNO' onblur='Form.blurData("scd018m_01_BLUR", "CRSNO", this.value, ["CRS_NAME"],[_i("QUERY", "CRS_NAME")], true); setDynSelect();'>
							<img src='/images/select.gif' alt='開窗選取' style='cursor:hand' onclick='Form.openPhraseWindow("scd018m_01_WINDOW", "AYEAR,SMS,CENTER_CODE", [_i("QUERY", "AYEAR").value, _i("QUERY", "SMS").value,_i("QUERY", "CENTER_CODE").value], "科目代碼,科目名稱", [_i("QUERY", "CRSNO"), _i("QUERY", "CRS_NAME")]); setDynSelect();'>
							<input type='text' Column='CRS_NAME' name='CRS_NAME' readonly>
						</td>

						<td align='right'>中心班級：</td>
						<td>
							<select name='CLASS_CODE'>
								<option value=''>請選擇</option>
							</select>
						</td>
					</tr>
					<tr>
						<td align='right'>學號：</td>
						<td colspan='5'><input type='text' name='STNO'  size='9' Column='STNO' value='<%=stno%>' <%=disabled%> ></td>
						
					</tr>
				</table>
				<!-- 查詢畫面結束 -->
			</td>
			<td width="13" background="<%=vr%>images/ap_search_06.jpg" alt="排版用圖示">&nbsp;</td>
		</tr>
		<tr>
			<td width="13"><img src="<%=vr%>images/ap_search_07.jpg" alt="排版用圖示" width="13" height="13"></td>
			<td width="100%"><img src="<%=vr%>images/ap_search_08.jpg" alt="排版用圖示" width="100%" height="13"></td>
			<td width="13"><img src="<%=vr%>images/ap_search_09.jpg" alt="排版用圖示" width="13" height="13"></td>
		</tr>
	</table>
	<!-- 查詢全畫面結束 -->
</form>
<!-- 定義查詢的 Form 結束 -->

<!-- 標題畫面起始 -->
<table width="96%" border="0" align="center" cellpadding="4" cellspacing="0" summary="排版用表格">
	<tr>
		<td>
			<table width="500" height="27" border="0" cellpadding="0" cellspacing="0">
				<tr>
					<td background="<%=vr%>images/ap_index_title.jpg" alt="排版用圖示">
						　　<span class="title">SCD018M_查詢學期成績</span>
					</td>
				</tr>
			</table>
		</td>
	</tr>
</table>
<!-- 標題畫面結束 -->

<!-- 定義查詢結果的 Form 起始 -->
<form name="RESULT" method="post" style="margin:10,0,0,0;">
<input type=hidden name="control_type">
<input type=hidden keyColumn="Y" name="STNO">
<input type=hidden keyColumn="Y" name="CRSNO">
<input type=hidden keyColumn="Y" name="CRS_NAME">
<input type=hidden keyColumn="Y" name="MIDMARK">
<input type=hidden keyColumn="Y" name="GMARK1">
<input type=hidden keyColumn="Y" name="CLASS_CODE">

	<!-- 查詢結果畫面起始 -->
	<table width="96%" border="0" align="center" cellpadding="0" cellspacing="0" summary="排版用表格">
		<tr>
			<td width="13"><img src="<%=vr%>images/ap_index_mtb_01.gif" alt="排版用圖示" width="13" height="14"></td>
			<td width="100%"><img src="<%=vr%>images/ap_index_mtb_02.gif" alt="排版用圖示" width="100%" height="14"></td>
			<td width="13"><img src="<%=vr%>images/ap_index_mtb_03.gif" alt="排版用圖示" width="13" height="14"></td>
		</tr>
		<tr>
			<td width="13" background="<%=vr%>images/ap_index_mtb_04.gif" alt="排版用圖示">&nbsp;</td>
			<td width="100%" bgcolor="#FFFFFF">
				<table width="100%" border="0" cellspacing="0" cellpadding="2" summary="排版用表格">
					<tr>
						<!-- 分頁字串起始 -->
						<td align=right nowrap>
							<div id="page">
								<b>
									<span id="pageStr"></span>
									【<input type='text' name='_scrollSize' size=2 value='10' style="text-align:center">
									<input type=button value='筆' onkeypress="setPageSize();"onclick="setPageSize();">
									<input type='text' name='_goToPage' size=2 value='1' style="text-align:right">
									/ <span id="totalPage"></span> <input type=button value='頁' onkeypress='gotoPage(null)'onclick='gotoPage(null)'>
									<span id="totalRow">0</span> 筆】

								</b>
							</div>
						</td>
						<!-- 分頁字串結束 -->
					</tr>
					<tr>
						<td align=left nowrap>
							<div id="page">
								<font color=purple><b><div id='gmarkEvalType'></div></b></font>
							</div>
						</td>
					</tr>
				</table>
				<!-- 查詢結果功能畫面起始 -->
				<div id="grid-scroll" style="overflow:auto;width:100%;height:380;"></div>
				<input type=hidden name='EXPORT_FILE_NAME'>
				<textarea name='EXPORT_CONTENT' cols=80 rows=3 style='display:none'></textarea>
				<textarea name='ALL_CONTENT' cols=80 rows=3 style='display:none'></textarea>
				<!-- 查詢結果功能畫面結束 -->
			</td>
			<td width="13" background="<%=vr%>images/ap_index_mtb_06.gif" alt="排版用圖示">&nbsp;</td>
		</tr>
		<tr>
			<td width="13"><img src="<%=vr%>images/ap_index_mtb_07.gif" alt="排版用圖示" width="13" height="15"></td>
			<td width="100%"><img src="<%=vr%>images/ap_index_mtb_08.gif" alt="排版用圖示" width="100%" height="15"></td>
			<td width="13"><img src="<%=vr%>images/ap_index_mtb_09.gif" alt="排版用圖示" width="13" height="15"></td>
		</tr>
	</table>
	<!-- 查詢結果畫面結束 -->
</form>
<!-- 定義查詢結果的 Form 結束 -->

<script>
	document.write ("<font color=\"white\">" + document.lastModified + "</font>");
	window.attachEvent("onload", page_init);
	window.attachEvent("onload", onloadEvent);
		function setDynSelect() {
			Form.getDynSelectFromPhrase(_i("QUERY","CLASS_CODE"), "SCD018M_01_DYNSELECT", true, "CENTER_CODE,CRSNO,AYEAR,SMS", Form.getInput("QUERY", "CENTER_CODE") + "," + Form.getInput("QUERY", "CRSNO")+ "," + Form.getInput("QUERY", "AYEAR")+ "," + Form.getInput("QUERY", "SMS"));
		}
</script>
</body>
</html>