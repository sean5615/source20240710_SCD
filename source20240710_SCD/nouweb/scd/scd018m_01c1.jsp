<%/*
----------------------------------------------------------------------------------
File Name		: scd018m_01c1
Author			: �����y
Description		: SCD018M_�d�߷�Ǵ����Z - ����� (javascript)
Modification Log	:

Vers		Date       	By            	Notes
--------------	--------------	--------------	----------------------------------
0.0.3       096/11/08   POTO        ���󳣧אּ�D����
0.0.2       096/05/15   WEN         ��SPEC���s�ק�
                                    1.Table���
                                    2.�令DAO���榡
                                    3.�ק��ӶץX���覡
0.0.1		096/03/13	�����y    	Code Generate Create
----------------------------------------------------------------------------------
*/%>
<%@ page contentType="text/html; charset=UTF-8" errorPage="/utility/errorpage.jsp" pageEncoding="MS950"%>
<%@ include file="/utility/header.jsp"%>
<%@ include file="/utility/jspageinit.jsp"%>

/** �פJ javqascript Class */
doImport ("Query.js, ErrorHandle.js, LoadingBar_0_2.js, Form.js, Ajax_0_2.js, ArrayUtil.js, ReSize.js, SortTable.js");

/** ��l�]�w������T */
var	printPage		=	"/scd/scd018m_01p1.jsp";	//�C�L����
var	editMode		=	"ADD";				//�s��Ҧ�, ADD - �s�W, MOD - �ק�
var	lockColumnCount		=	-1;				//��w����
var	listShow		=	false;				//�O�_�@�i�J��ܸ��
var	_privateMessageTime	=	-1;				//�T����ܮɶ�(���ۭq�� -1)
var	pageRangeSize		=	10;				//�e���@����ܴX�����
var	controlPage		=	"/scd/scd018m_01c2.jsp";	//�����
var	checkObj		=	new checkObj();			//�ֿ露��
var	queryObj		=	new queryObj();			//�d�ߤ���
var	importSelect		=	false;				//�פJ������\��
var	noPermissAry		=	new Array();			//�S���v�����}�C

/** ������l�� */
function page_init()
{
	page_init_start();

	editMode	=	"NONE";
	/** �v���ˮ� */
	securityCheck();

	/** === ��l���]�w === */
	/** ��l�W�h�a�Ӫ� Key ��� */
	iniMasterKeyColumn();

	/** ��l�d����� */
	//if(Form.getInput("QUERY", "QQ") == '511'){
	//	Form.iniFormSet('QUERY', 'AYEAR','F',3,'N', 'R', 0,'M',3,'S',3);
	//	Form.iniFormSet('QUERY', 'SMS', 'R', 0);	
	//}else{
		Form.iniFormSet('QUERY', 'AYEAR','F',3,'N', 'R', 0,'M',3,'S',3,'D',0);
		Form.iniFormSet('QUERY', 'SMS', 'R', 0,'D',0);	
	//}
	Form.iniFormSet('QUERY', 'CENTER_CODE', 'N1', 'M',  2, 'A');
	Form.iniFormSet('QUERY', 'CRSNO', 'N','M', 6, 'A');
	Form.iniFormSet('QUERY', 'CRS_NAME', 'M',  6, 'A');
	Form.iniFormSet('QUERY', 'CLASS_CODE', 'M',  6, 'A','N1','KV');
	Form.iniFormSet('QUERY', 'STNO', 'M',  9, 'EN','A','u');

	/** ��l�s����� */
	loadind_.showLoadingBar (15, "��l��짹��");
	/** ================ */

	/** === �]�w�ˮֱ��� === */
	/** �d����� */
	Form.iniFormSet('QUERY', 'AYEAR', 'AA', 'chkForm', '�Ǧ~');
	Form.iniFormSet('QUERY', 'SMS', 'AA', 'chkForm', '�Ǵ�');
	Form.iniFormSet('QUERY', 'CENTER_CODE', 'AA', 'chkForm', '���ߧO');
	/*
	Form.iniFormSet('QUERY', 'CRSNO', 'AA', 'chkForm', '���');
	Form.iniFormSet('QUERY', 'CLASS_CODE', 'AA', 'chkForm', '�Z��');
	*/

	/** �s����� */
	loadind_.showLoadingBar (20, "�]�w�ֱ��󧹦�");
	/** ================ */

	page_init_end();
}

/**
��l�� Grid ���e
@param	stat	�I�s���A(init -> ������l��)
*/
function iniGrid(stat)
{
	var	gridObj	=	new Grid();

	iniGrid_start(gridObj)

	/** �]�w���Y */
	gridObj.heaherHTML.append
	(
		"<table id=\"RsultTable\" class='sortable' width=\"100%\" border=\"1\" cellpadding=\"2\" cellspacing=\"0\" bordercolor=\"#E6E6E6\">\
			<tr class=\"mtbGreenBg\">\
				<td resize='on' nowrap>�Ǹ�</td>\
				<td resize='on' nowrap>�m�W</td>\
				<td resize='on' nowrap>��إN�X</td>\
				<td resize='on' nowrap>��ئW��</td>\
				<td resize='on' nowrap>�Z�ŦW��</td>\
				<td resize='on' nowrap>�Ǥ���</td>\
				<td resize='on' nowrap>���ɤ@</td>\
				<td resize='on' nowrap>���ɤG</td>\
				<td resize='on' nowrap>���ɤT</td>\
				<td resize='on' nowrap>����</td>\
				<td resize='on' nowrap>����</td>\
				<td resize='on' nowrap>����</td>\
				<td resize='on' nowrap>�Ǵ�</td>\
			</tr>"
	);

	if (stat == "init" && !listShow)
	{
		/** ��l�ƤΤ���ܸ�ƥu�q���Y */
		document.getElementById("grid-scroll").innerHTML	=	gridObj.heaherHTML.toString().replace(/\t/g, "") + "</table>";
		Message.hideProcess();
	}
	else
	{
		/** �����϶��P�B */
		Form.setInput ("QUERY", "pageSize",	Form.getInput("RESULT", "_scrollSize"));
		Form.setInput ("QUERY", "pageNo",	Form.getInput("RESULT", "_goToPage"));
		
		/** �B�z�s�u����� */
		var	callBack	=	function iniGrid.callBack(ajaxData)
		{
			if (ajaxData == null)
				return;

			/** �]�w�� */
			var	keyValue	=	"";
			var	editStr		=	"";
			var	delStr		=	"";
			var	exportBuff	=	new StringBuffer();
	        var GMARK1 ="";
	        var GMARK2 ="";
	        var GMARK3 = "";
	        var GMARK_AVG ="";
	        var MIDMARK ="";
	        var FNLMARK ="";
			var AVG_MARK ="";
			var SMS_1 ="";
										
			if("2" == ajaxData.data[0].GMARK_EVAL_TIMES) {
			document.getElementById("gmarkEvalType").innerHTML = "���Ǵ����ɦ��Z���q����<font color = 'red'>�p�G��</font>�A���ɤT���Z�N�H��--���e�{�A���ɦ��Z�����Z�@�Φ��Z�G�������C";
			} else {
			document.getElementById("gmarkEvalType").innerHTML = "";
			}
			
			for (var i = 0; i < ajaxData.data.length; i++, gridObj.rowCount++)
			{
				keyValue	=	"CRSNO|" + ajaxData.data[i].CRSNO + "|CRS_NAME|" + ajaxData.data[i].CRS_NAME +"|MIDMARK|" + ajaxData.data[i].MIDMARK +"|STNO|" + ajaxData.data[i].STNO +"|GMARK1|" + ajaxData.data[i].GMARK1 +"";	            
	            if(Form.getInput("QUERY", "AYEAR")==Form.getInput("QUERY", "AYEAR_SCD")&&Form.getInput("QUERY", "SMS")==Form.getInput("QUERY", "SMS_SCD")){
				//�p�G�O��Ǧ~�� �~�ݭn�P�_�۰O �]���H�e���ɪ�Ӫ����Z �èS���۰O
					if(ajaxData.data[i].GMARK_ANNO_MK == 'Y' || ajaxData.data[i].GMARK_LOCK_MK == 'Y'||Form.getInput("QUERY", "QQ") == '511') {
		                 GMARK1 =  ajaxData.data[i].GMARK1 ;
		                 GMARK2 =  ajaxData.data[i].GMARK2 ;
		                 GMARK3 =  ajaxData.data[i].GMARK3 ;
		                 GMARK_AVG =   ajaxData.data[i].GMARK_AVG ;
		            }else{
					     GMARK1="";
					     GMARK2 ="";
					     GMARK3 = "";
					     GMARK_AVG ="";
				    }
		            if(ajaxData.data[i].MIDMARK_ANNO_MK == 'Y' ||ajaxData.data[i].MIDMARK_LOCK_MK == 'Y'||Form.getInput("QUERY", "QQ") == '511') {
		                 MIDMARK =  ajaxData.data[i].MIDMARK ;
		            }else{
		                 MIDMARK="";
		            }
		            if(ajaxData.data[i].FNLMARK_ANNO_MK == 'Y' ||ajaxData.data[i].FNLMARK_LOCK_MK == 'Y'||Form.getInput("QUERY", "QQ") == '511') {
		                 FNLMARK =  ajaxData.data[i].FNLMARK ;
		            }else{
		                 FNLMARK="";
		            }
				
				}else{
					GMARK1 =  ajaxData.data[i].GMARK1 ;
					GMARK2 =  ajaxData.data[i].GMARK2 ;
					GMARK3 =  ajaxData.data[i].GMARK3 ;
					GMARK_AVG =   ajaxData.data[i].GMARK_AVG ;
					MIDMARK =  ajaxData.data[i].MIDMARK ;
					FNLMARK =  ajaxData.data[i].FNLMARK ;
				}
	            
				SMS_1 = ajaxData.data[i].SMS ;
				AVG_MARK = ajaxData.data[i].AVG_MARK ;
				if(AVG_MARK==""){
					AVG_MARK = "";
				}else{
					if(AVG_MARK=='-1'){
						AVG_MARK ="��";
					}else{
						if(SMS_1 == '3') {
							if(FNLMARK=='-1'){
								AVG_MARK ="��";
							}               
			            }else{
							if(FNLMARK=='-1'&&MIDMARK=='-1'){
								AVG_MARK ="��";
							}
			            }
					}				
				}
				//by poto QAscd0029
				if(SMS_1=='3'){
					MIDMARK = '-';
				}
				
				gridObj.gridHtml.append
				(
					"<tr class=\"listColor0" + ((gridObj.rowCount % 2) + 1) + "\">\
						<td>" + ajaxData.data[i].STNO 	    + "&nbsp;</td>\
						<td>" + ajaxData.data[i].NAME 	    + "&nbsp;</td>\
						<td>" + ajaxData.data[i].CRSNO 	    + "&nbsp;</td>\
						<td>" + ajaxData.data[i].CRS_NAME 	+ "&nbsp;</td>\
						<td>" + ajaxData.data[i].CLASS_CODE 	+ "&nbsp;</td>\
						<td>" + ajaxData.data[i].CRD 		+ "&nbsp;</td>\
						<td>" + ((GMARK1 == '-1')?"��":GMARK1) 	+ "&nbsp;</td>\
						<td>" + ((GMARK2 == '-1')?"��":GMARK2) 	+ "&nbsp;</td>\
						<td>" + ((GMARK3 == '-1')?"��":GMARK3) 	+ "&nbsp;</td>\
						<td>" + ((GMARK_AVG == '-1')?"��":GMARK_AVG)  	+ "&nbsp;</td>\
						<td>" + ((MIDMARK == '-1')?"��":MIDMARK)  	+ "&nbsp;</td>\
						<td>" + ((FNLMARK == '-1')?"��":FNLMARK)  	+ "&nbsp;</td>\
						<td>" +AVG_MARK+ "&nbsp;</td>\
					</tr>"
				);

				exportBuff.append
				(

				);
			}
			gridObj.gridHtml.append ("</table>");
			Form.setInput ("RESULT", "ALL_CONTENT", exportBuff.toString());
			/** �L�ŦX��� */
			if (ajaxData.data.length == 0){
				gridObj.gridHtml.append ("<font color=red><b>�@�@�@�d�L�ŦX���!!</b></font>");
			}	
			iniGrid_end(ajaxData, gridObj);
		}		
		sendFormData("QUERY", controlPage, "QUERY_MODE", callBack);
	}
}

function doExport() {	
	var CRSNO = Form.getInput("QUERY", "CRSNO");
	var CENTER_CODE = Form.getInput("QUERY", "CENTER_CODE");
	var STNO = Form.getInput("QUERY", "STNO");	
	if((STNO==""||STNO==null)&&(CENTER_CODE==""||CENTER_CODE==null)&&(CRSNO==""||CRSNO==null)){		
		alert("��ءA���ߧO�A�Ǹ��A�оܤ@��J");
		return;
	}
	Form.setInput('QUERY', 'control_type','EXPORT_ALL_MODE');
	Form.doSubmit('QUERY',controlPage,'post','');		
}

/** �d�ߥ\��ɩI�s */
function doQuery(AYEAR,SMS)
{
	doQuery_start();
	/** === �۩w�ˬd === */
	loadind_.showLoadingBar (8, "�۩w�ˮֶ}�l");
	
	var ina=eval(Form.getInput("QUERY", "AYEAR"));
	var ins=eval(Form.getInput("QUERY", "SMS"));	
	
	//if (Form.getInput("QUERY", "SYS_CD") == "")
		//Form.errAppend(AYEAR+" "+SMS+"!!");
	/*	
	if(SMS=="3"){	
		if(ina != AYEAR)
			Form.errAppend("�u��d�߷�Ǵ�,�e�Ǵ�,�e�e�Ǵ�!!");
	}else if(SMS=="1"){
		if(ina == AYEAR && ins == 1)
			var suc="";
		else if(ina == (AYEAR-1) && ins == 2)
			var suc="";		
		else if(ina == (AYEAR-1) && ins == 1)
			var suc="";		
		else
			Form.errAppend("�u��d�߷�Ǵ�,�e�Ǵ�,�e�e�Ǵ�!!");		
	}else{
		if(ina == AYEAR && ins == 2)
			var suc="";		
		else if(ina == AYEAR && ins == 1)
			var suc="";		
		else if(ina == (AYEAR-1) && ins == 3)
			var suc="";		
		else
			Form.errAppend("�u��d�߷�Ǵ�,�e�Ǵ�,�e�e�Ǵ�!!");		
	}
	*/	
	return doQuery_end();
}

/** �s�W�\��ɩI�s */
function doAdd(){}

/** �ק�\��ɩI�s */
function doModify(){}

/** �s�ɥ\��ɩI�s */
function doSave(){}

/** ============================= ���ץ��{����m�� ======================================= */
/** �]�w�\���v�� */
function securityCheck()
{
	try
	{
		/** �d�� */
		if (!<%=AUTICFM.securityCheck (session, "QRY")%>)
		{
			noPermissAry[noPermissAry.length]	=	"QRY";
			try{Form.iniFormSet("QUERY", "QUERY_BTN", "D", 1);}catch(ex){}
		}
		/** �s�W */
		if (!<%=AUTICFM.securityCheck (session, "ADD")%>)
		{
			noPermissAry[noPermissAry.length]	=	"ADD";
			editMode	=	"NONE";
			try{Form.iniFormSet("EDIT", "ADD_BTN", "D", 1);}catch(ex){}
		}
		/** �ק� */
		if (!<%=AUTICFM.securityCheck (session, "UPD")%>)
		{
			noPermissAry[noPermissAry.length]	=	"UPD";
		}
		/** �s�W�έק� */
		if (!chkSecure("ADD") && !chkSecure("UPD"))
		{
			try{Form.iniFormSet("EDIT", "SAVE_BTN", "D", 1);}catch(ex){}
		}
		/** �R�� */
		if (!<%=AUTICFM.securityCheck (session, "DEL")%>)
		{
			noPermissAry[noPermissAry.length]	=	"DEL";
			try{Form.iniFormSet("RESULT", "DEL_BTN", "D", 1);}catch(ex){}
		}
		/** �ץX */
		if (!<%=AUTICFM.securityCheck (session, "EXP")%>)
		{
			noPermissAry[noPermissAry.length]	=	"EXP";
			try{Form.iniFormSet("RESULT", "EXPORT_BTN", "D", 1);}catch(ex){}
			try{Form.iniFormSet("QUERY", "EXPORT_ALL_BTN", "D", 1);}catch(ex){}
		}
		/** �C�L */
		if (!<%=AUTICFM.securityCheck (session, "PRT")%>)
		{
			noPermissAry[noPermissAry.length]	=	"PRT";
			try{Form.iniFormSet("RESULT", "PRT_BTN", "D", 1);}catch(ex){}
			try{Form.iniFormSet("QUERY", "PRT_ALL_BTN", "D", 1);}catch(ex){}
		}
	}
	catch (ex)
	{
	}
}
/** �ˬd�v�� - ���v��/�L�v��(true/false) */
function chkSecure(secureType)
{
	if (noPermissAry.toString().indexOf(secureType) != -1)
		return false;
	else
		return true
}
/** ====================================================================================== */
/** ��l�W�h�a�Ӫ� Key ��� */
function iniMasterKeyColumn()
{
	/** �D Detail �������B�z */
	if (typeof(keyObj) == "undefined")
		return;
	/** ��� */
	for (keyName in keyObj)
	{
		try {Form.iniFormSet("QUERY", keyName, "V", keyObj[keyName], "R", 0);}catch(ex){};
		try {Form.iniFormSet("EDIT", keyName, "V", keyObj[keyName], "R", 0);}catch(ex){};
	}
	Form.iniFormColor();
}
/** �B�z�C�L�ʧ@ */
function doPrint(printForm)
{	
	var CRSNO = Form.getInput("QUERY", "CRSNO");
	var CENTER_CODE = Form.getInput("QUERY", "CENTER_CODE");
	var STNO = Form.getInput("QUERY", "STNO");		
	if((STNO==""||STNO==null)&&(CENTER_CODE==""||CENTER_CODE==null)&&(CRSNO==""||CRSNO==null)){		
		alert("��ءA���ߧO�A�Ǹ��A�оܤ@��J");
		return;
	}	
	/** ���� onsubmit �\�ਾ��ưe�X */
	event.returnValue	=	false;

	/** �}�l�B�z */
	Message.showProcess();

	if (printForm == "RESULT")
	{
		if (!Form.chkCheckBoxForName("RESULT", "chkBox"))
		{
			Message.showMessage("��������ɮצb�i��B�z!!");
			/** ����B�z */
			Message.hideProcess();

			return;
		}
	}
	else
	{
		/** �ˮֳ]�w���*/
		Form.startChkForm("QUERY");

		/** ��ֿ��~�B�z */
		if (!queryObj.valideMessage (Form))
			return;
	}

	var	printWin	=	WindowUtil.openPrintWindow("", "Print");

	if (printForm == "RESULT")
	{
		checkObj.setResultKey();
		Form.doSubmit("RESULT", printPage + "?PRINTFORM=" + printForm, "post", "Print");
	}
	else
	{
		Form.iniFormSet('QUERY', 'AYEAR','R', 0,'D', 0);
		Form.iniFormSet('QUERY', 'SMS', 'R', 0,'D', 0);		
		Form.doSubmit("QUERY", printPage + "?PRINTFORM=" + printForm, "post", "Print");
		if(Form.getInput("QUERY", "QQ") == '511'){
			Form.iniFormSet('QUERY', 'AYEAR','R', 0,'D', 0);
			Form.iniFormSet('QUERY', 'SMS', 'R', 0,'D', 0);	
		}else{
			Form.iniFormSet('QUERY', 'AYEAR','R', 1,'D', 1);
			Form.iniFormSet('QUERY', 'SMS', 'R', 1,'D', 1);	
		}
		
	}	
	printWin.focus();

	/** ����B�z */
	Message.hideProcess();
}