<%
/**************************************************************************************************************************
* Program Name  : 본인확인 V4 Sample JSP 
* File Name     : pcc_V3_input_seed_v4.jsp
* Comment       : 
* History       :  2025.12.03 신규
*
**************************************************************************************************************************/
%>

<%@ page  contentType = "text/html;charset=utf-8"%>
<%@ page import ="java.util.*,java.text.SimpleDateFormat,comm.*"%>

<%
        //날짜 생성
        Calendar today = Calendar.getInstance();
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmmss");
        String day = sdf.format(today.getTime());
    	Date currentDate = new Date();
    	
    	
        java.util.Random ran = new Random();
        //랜덤 문자 길이
        int numLength = 6;
        String randomStr = "";

        for (int i = 0; i < numLength; i++) {
            //0 ~ 9 랜덤 숫자 생성
            randomStr += ran.nextInt(10);
        }

		//reqNum은 최대 40byte 까지 사용 가능
        String reqNum = day + randomStr; // 고정값으로 사용가능
		String certDate=day;

%>

<html>
    <head>
        <title>서울평가정보 본인확인서비스 테스트</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <style>
            body,p,ol,ul,td
            {
                font-family: 굴림;
                font-size: 12px;
            }

            a:link { size:9px;color:#000000;text-decoration: none; line-height: 12px}
            a:visited { size:9px;color:#555555;text-decoration: none; line-height: 12px}
            a:hover { color:#ff9900;text-decoration: none; line-height: 12px}

            .style1 {
                color: #6b902a;
                font-weight: bold;
            }
            .style2 {
                color: #666666
            }
            .style3 {
                color: #3b5d00;
                font-weight: bold;
            }
        </style>
    </head>
    <body onload="document.reqCBAForm.id.focus();" bgcolor="#FFFFFF" topmargin=0 leftmargin=0 marginheight=0 marginwidth=0>
        <center>
            <span class="style1">서울평가정보 본인확인서비스 테스트</span><br>

            <form name="reqCBAForm" method="post" action="./pcc_V3_sample_seed_v4_real.jsp">
                <table cellpadding=1 cellspacing=1>
                    <tr>
                        <td align=center>회원사아이디</td>
                        <td align=left><input type="text" name="id" size='41' maxlength ='8' value = "비즈사이렌 로그인 아이디"></td>
                    </tr>
                    <tr>
                        <td align=center>서비스번호</td>
                        <td align=left><input type="text" name="srvNo" size='41' maxlength ='6' value= "비즈사이렌에서 생성한 서비스번호"></td> 
                    </tr>
                    <tr>
                        <td align=center>요청번호</td>
                        <td align=left><input type="text" name="reqNum" size='14' maxlength ='14' value='<%=reqNum%>'></td>
                    </tr>
					<tr>
                        <td align=center>인증구분</td>
                        <td align=left>
                            <select name="certGb" style="width:300">
                                <option value="H">휴대폰</option>
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <td align=center>결과수신URL</td>
        				<td align=left><input type="text" name="retUrl" size="100" value="71https://응답받을 url"></td>                  
					</tr>
					<tr>
                        <td align=center>버전정보</td>
                        <td align=left>
                            <select name="verSion" style="width:300">
                                <option value="3">API</option>
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <td align=center>요청시간</td>
                        <td align=left><input type="text" name="certDate" size='41' maxlength ='40' value='<%=certDate%>'></td>
                    </tr>

                </table>
                <br><br>
                <input type="submit" value="본인확인서비스V4 테스트">
            </form>
            <br>
            <br>
            이 Sample화면은 서울평가정보 본인확인서비스 테스트를 위해 제공하고 있는 화면입니다.<br>
            <br>
        </center>
    </body>
</html>