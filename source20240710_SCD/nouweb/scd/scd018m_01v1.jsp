<%/*
----------------------------------------------------------------------------------
File Name		: scd018m_01v1
Author			: �����y
Description		: SCD018M_�d�߷�Ǵ����Z - ��ܭ���
Modification Log	:

Vers		Date       	By            	Notes
--------------	--------------	--------------	----------------------------------
0.0.2       096/05/15   WEN         ��SPEC���s�ק�
                                    1.Table���
                                    2.�令DAO���榡
                                    3.�ק��ӶץX���覡
0.0.1		096/03/13	�����y    	Code Generate Create
0.0.3		096/09/25	poto    	�ק﮳���ե��� �M�ƧǬ��
0.0.4		096/10/01	poto    	���+distinct
----------------------------------------------------------------------------------
*/%>
<%@ page contentType="text/html; charset=UTF-8" errorPage="/utility/errorpage.jsp" pageEncoding="MS950"%>
<%@ include file="/utility/header.jsp"%>
<%@ include file="/utility/viewpagedbinit.jsp"%>
<%@ page import="java.util.* , com.nou.sys.dao.*"%>
<jsp:useBean id="AUTGETRANGE" scope="session" class="com.nou.aut.AUTGETRANGE" />

<%
	/**���o�Ǧ~�����*/
	String QQ="";//�������O
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
	String PRVLG_TYPE = "";	//���ߩάO����
	String stno = null;
	String idno = "";
	String CENTER_CODE = null;
	Vector dep = null;
	String disabled= null;
	StringBuffer sql = new StringBuffer();
	dep = AUTGETRANGE.getDEP_CODE("3","3");		//�v���O(PRVLG_TP[3.����])�B�����O(ID_TP[3.��F�H��])
	if(dep.size()>0){							//�v���O(PRVLG_TP[4.����])�B�����O(ID_TP[3.��F�H��])
		PRVLG_TYPE ="3";
		stno="";
		QQ = "511";
	}else if(ID_TYPE.equals("2")){				//�v���O(PRVLG_TP[1.�ӧO])�B�����O(ID_TP[2.�Юv])
		PRVLG_TYPE ="1";
		stno="";
		dep = AUTGETRANGE.getDEP_CODE("1","2");
		if(dep.size()>0){
			stno="";
			CENTER_CODE = getDepStr(dep);
		}
	}else if(ID_TYPE.equals("1")){				//�v���O(PRVLG_TP[1.�ӧO])�B�����O(ID_TP[1.�ǥ�])
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
		 //�v���O(PRVLG_TP[4.����])�B�����O(ID_TP[3.��F�H��])
		stno="";
		dep = AUTGETRANGE.getDEP_CODE("4","3");
		CENTER_CODE = getDepStr(dep);
	}
	/**���o���ߧO */
	sql.append("NOU#");
	sql.append(" SELECT A.CODE AS SELECT_VALUE,A.CODE_NAME AS SELECT_TEXT ");
	sql.append(" FROM SYST001 A ");
	sql.append(" WHERE A.KIND = 'CENTER_CODE' ");
	if (CENTER_CODE != null)sql.append(" AND A.CODE IN (").append(CENTER_CODE).append(")");
	sql.append(" AND A.CODE!= '00' ");// by poto
	sql.append(" ORDER BY  A.CODE ");
	session.setAttribute("scd018M_01_SELECT", sql.toString());

	/**���o��ئW��*/
	sql.setLength(0);
	sql.append("NOU#");
   sql.append("SELECT A.CRSNO, B.CRS_NAME ");
   sql.append("FROM ( ");
   if("1".equals(ID_TYPE)) { //�ǥ�
      sql.append("SELECT distinct CRSNO ");//by poto ���n����ح���
      sql.append("FROM PLAT007 ");
      sql.append(" WHERE AYEAR = '[AYEAR]' AND SMS = '[SMS]'");
      sql.append("AND STNO = '" + stno + "' ");
   } else if("2".equals(ID_TYPE)){ //�Ѯv
      sql.append("SELECT distinct a.CRSNO ");
      sql.append("FROM PLAT012 a ");
	  sql.append("JOIN REGT007 C ON A.AYEAR=C.AYEAR AND A.SMS=C.SMS AND A.CRSNO=C.CRSNO AND A.CLASS_CODE=C.ASS_CLASS_CODE ");	  
      sql.append("WHERE a.AYEAR = '[AYEAR]' AND a.SMS = '[SMS]' ");	  
      sql.append("AND a.TCH_IDNO = '" + session.getAttribute("USER_IDNO") + "' ");
   } else { //����
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

	/**���o�Z��*/
	String TCH_IDNO = "";
	sql.setLength(0);
	sql.append("NOU#");	
	if(ID_TYPE.equals("2")){ //�����O���Юv
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
	}else if(ID_TYPE.equals("1")){//�����O���ǥ�
		sql.append(" SELECT DISTINCT A.TUT_CLASS_CODE AS SELECT_TEXT, A.TUT_CLASS_CODE AS SELECT_VALUE ");
		sql.append(" FROM PLAT007 A, ");
		sql.append("	( SELECT CENTER_ABRCODE FROM SYST002 WHERE CENTER_CODE = '[CENTER_CODE]') S ");
		sql.append(" WHERE A.AYEAR = '[AYEAR]' AND A.SMS = '[SMS]'");
		sql.append(" AND A.CENTER_ABRCODE = S.CENTER_ABRCODE");
		sql.append(" AND STNO = '").append(stno).append("'");
		session.setAttribute("SCD018M_01_DYNSELECT", sql.toString());
	}else{					//����
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
		<p>�z���s�������䴩JavaScript�y�k�A���O�ä��v�T�z��������������e</p>
	</noscript>
</head>
<body background="<%=vr%>images/ap_index_bg.jpg" alt="�I����" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" >

<!-- �w�q�d�ߪ� Form �_�l -->
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
	<input type=hidden name="QQ" value='<%=QQ%>'  ><!--���U�դH��-->


	<!-- �d�ߥ��e���_�l -->
	<TABLE id="QUERY_DIV" width="96%" border="0" align="center" cellpadding="0" cellspacing="0" summary="�ƪ��Ϊ��">
		<tr>
			<td width="13"><img src="<%=vr%>images/ap_search_01.jpg" alt="�ƪ��ιϥ�" width="13" height="12"></td>
			<td width="100%"><img src="<%=vr%>images/ap_search_02.jpg" alt="�ƪ��ιϥ�" width="100%" height="12"></td>
			<td width="13"><img src="<%=vr%>images/ap_search_03.jpg" alt="�ƪ��ιϥ�" width="13" height="12"></td>
		</tr>
		<tr>
			<td width="13" background="<%=vr%>images/ap_search_04.jpg" alt="�ƪ��ιϥ�">&nbsp;</td>
			<td width="100%" valign="top" bgcolor="#C5E2C3">
				<!-- ���s�e���_�l -->
				<table width="100%" border="0" align="center" cellpadding="2" cellspacing="0" summary="�ƪ��Ϊ��">
					<tr class="mtbGreenBg">
						<td align=left>�i�d�ߵe���j</td>
						<td align=right>
							<div id="serach_btn">
								<input type=button class="btn" value='�M  ��' onkeypress="doReset();"onclick="doReset();">
								<input type=submit class="btn" value='�d  ��' name='QUERY_BTN'>
								<input type=button class="btn" value='�C  �L' name="PRT_ALL_BTN" onkeypress="doPrint('QUERY');"onclick="doPrint('QUERY');">
								<% if(PRVLG_TYPE.equals("3")) {%>
									<input type=button class="btn" value='��  �X' name="EXPORT_ALL_BTN" onkeypress="doExport();"onclick="doExport();" >								
								<%}else{%>
									<input type=button class="btn" value='��  �X' name="EXPORT_ALL_BTN" onkeypress="doExport();"onclick="doExport();" disabled>								
								<%}%>
							</div>
						</td>
					</tr>
				</table>
				<!-- ���s�e������ -->

				<!-- �d�ߵe���_�l -->
				<table id="table1" width="100%" border="0" align="center" cellpadding="2" cellspacing="1" summary="�ƪ��Ϊ��">
					<tr>
						<td align='right'>�Ǧ~��<font color=red>��</font>�G</td>
						<td>
							<input type='text' name='AYEAR' Column='AYEAR' onchange= 'setDynSelect();'>							
							<select name='SMS'onchange='setDynSelect();'>
								<option>�п��</option>
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
						<td align='right'>���ߧO<font color=red>��</font>�G</td>
						<td>
							<select name='CENTER_CODE' Column='CENTER_CODE'>
								<% if((ID_TYPE.equals("3")||ID_TYPE.equals("7"))&&"3".equals(PRVLG_TYPE)) {%>
								<option value=''>�п��</option>
								<% } %>
								<script>Form.getSelectFromPhrase("scd018M_01_SELECT", "", "");</script>
							</select>
						</td>
						<% } %>
					</tr>

					<tr>  
						<td align='right'>��ءG</td>
						<td>
							<input type='text' size='5' Column='CRSNO' name='CRSNO' onblur='Form.blurData("scd018m_01_BLUR", "CRSNO", this.value, ["CRS_NAME"],[_i("QUERY", "CRS_NAME")], true); setDynSelect();'>
							<img src='/images/select.gif' alt='�}�����' style='cursor:hand' onclick='Form.openPhraseWindow("scd018m_01_WINDOW", "AYEAR,SMS,CENTER_CODE", [_i("QUERY", "AYEAR").value, _i("QUERY", "SMS").value,_i("QUERY", "CENTER_CODE").value], "��إN�X,��ئW��", [_i("QUERY", "CRSNO"), _i("QUERY", "CRS_NAME")]); setDynSelect();'>
							<input type='text' Column='CRS_NAME' name='CRS_NAME' readonly>
						</td>

						<td align='right'>���߯Z�šG</td>
						<td>
							<select name='CLASS_CODE'>
								<option value=''>�п��</option>
							</select>
						</td>
					</tr>
					<tr>
						<td align='right'>�Ǹ��G</td>
						<td colspan='5'><input type='text' name='STNO'  size='9' Column='STNO' value='<%=stno%>' <%=disabled%> ></td>
						
					</tr>
				</table>
				<!-- �d�ߵe������ -->
			</td>
			<td width="13" background="<%=vr%>images/ap_search_06.jpg" alt="�ƪ��ιϥ�">&nbsp;</td>
		</tr>
		<tr>
			<td width="13"><img src="<%=vr%>images/ap_search_07.jpg" alt="�ƪ��ιϥ�" width="13" height="13"></td>
			<td width="100%"><img src="<%=vr%>images/ap_search_08.jpg" alt="�ƪ��ιϥ�" width="100%" height="13"></td>
			<td width="13"><img src="<%=vr%>images/ap_search_09.jpg" alt="�ƪ��ιϥ�" width="13" height="13"></td>
		</tr>
	</table>
	<!-- �d�ߥ��e������ -->
</form>
<!-- �w�q�d�ߪ� Form ���� -->

<!-- ���D�e���_�l -->
<table width="96%" border="0" align="center" cellpadding="4" cellspacing="0" summary="�ƪ��Ϊ��">
	<tr>
		<td>
			<table width="500" height="27" border="0" cellpadding="0" cellspacing="0">
				<tr>
					<td background="<%=vr%>images/ap_index_title.jpg" alt="�ƪ��ιϥ�">
						�@�@<span class="title">SCD018M_�d�߾Ǵ����Z</span>
					</td>
				</tr>
			</table>
		</td>
	</tr>
</table>
<!-- ���D�e������ -->

<!-- �w�q�d�ߵ��G�� Form �_�l -->
<form name="RESULT" method="post" style="margin:10,0,0,0;">
<input type=hidden name="control_type">
<input type=hidden keyColumn="Y" name="STNO">
<input type=hidden keyColumn="Y" name="CRSNO">
<input type=hidden keyColumn="Y" name="CRS_NAME">
<input type=hidden keyColumn="Y" name="MIDMARK">
<input type=hidden keyColumn="Y" name="GMARK1">
<input type=hidden keyColumn="Y" name="CLASS_CODE">

	<!-- �d�ߵ��G�e���_�l -->
	<table width="96%" border="0" align="center" cellpadding="0" cellspacing="0" summary="�ƪ��Ϊ��">
		<tr>
			<td width="13"><img src="<%=vr%>images/ap_index_mtb_01.gif" alt="�ƪ��ιϥ�" width="13" height="14"></td>
			<td width="100%"><img src="<%=vr%>images/ap_index_mtb_02.gif" alt="�ƪ��ιϥ�" width="100%" height="14"></td>
			<td width="13"><img src="<%=vr%>images/ap_index_mtb_03.gif" alt="�ƪ��ιϥ�" width="13" height="14"></td>
		</tr>
		<tr>
			<td width="13" background="<%=vr%>images/ap_index_mtb_04.gif" alt="�ƪ��ιϥ�">&nbsp;</td>
			<td width="100%" bgcolor="#FFFFFF">
				<table width="100%" border="0" cellspacing="0" cellpadding="2" summary="�ƪ��Ϊ��">
					<tr>
						<!-- �����r��_�l -->
						<td align=right nowrap>
							<div id="page">
								<b>
									<span id="pageStr"></span>
									�i<input type='text' name='_scrollSize' size=2 value='10' style="text-align:center">
									<input type=button value='��' onkeypress="setPageSize();"onclick="setPageSize();">
									<input type='text' name='_goToPage' size=2 value='1' style="text-align:right">
									/ <span id="totalPage"></span> <input type=button value='��' onkeypress='gotoPage(null)'onclick='gotoPage(null)'>
									<span id="totalRow">0</span> ���j

								</b>
							</div>
						</td>
						<!-- �����r�굲�� -->
					</tr>
					<tr>
						<td align=left nowrap>
							<div id="page">
								<font color=purple><b><div id='gmarkEvalType'></div></b></font>
							</div>
						</td>
					</tr>
				</table>
				<!-- �d�ߵ��G�\��e���_�l -->
				<div id="grid-scroll" style="overflow:auto;width:100%;height:380;"></div>
				<input type=hidden name='EXPORT_FILE_NAME'>
				<textarea name='EXPORT_CONTENT' cols=80 rows=3 style='display:none'></textarea>
				<textarea name='ALL_CONTENT' cols=80 rows=3 style='display:none'></textarea>
				<!-- �d�ߵ��G�\��e������ -->
			</td>
			<td width="13" background="<%=vr%>images/ap_index_mtb_06.gif" alt="�ƪ��ιϥ�">&nbsp;</td>
		</tr>
		<tr>
			<td width="13"><img src="<%=vr%>images/ap_index_mtb_07.gif" alt="�ƪ��ιϥ�" width="13" height="15"></td>
			<td width="100%"><img src="<%=vr%>images/ap_index_mtb_08.gif" alt="�ƪ��ιϥ�" width="100%" height="15"></td>
			<td width="13"><img src="<%=vr%>images/ap_index_mtb_09.gif" alt="�ƪ��ιϥ�" width="13" height="15"></td>
		</tr>
	</table>
	<!-- �d�ߵ��G�e������ -->
</form>
<!-- �w�q�d�ߵ��G�� Form ���� -->

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