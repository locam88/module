<%
/**************************************************************************************************************************
* Program Name  : 본인확인 V4 API Sample JSP 
* File Name     : pcc_V3_sample_seed_v4.jsp
* Comment       : 
* History       :  2025.12.03 신규
*
**************************************************************************************************************************/
%>
<%
    response.setHeader("Pragma", "no-cache" );
    response.setDateHeader("Expires", 0);
    response.setHeader("Pragma", "no-store");
    response.setHeader("Cache-Control", "no-cache" );
%>
<%@ page  contentType = "text/html;charset=utf-8"%>
<%@ page import = "java.util.*,comm.*" %> 

<%@ page import = "java.io.UnsupportedEncodingException" %>
<%@ page import = "java.net.URLEncoder" %> 
<%@ page import = "java.net.URLDecoder" %> 
<%@ page import = "java.util.*" %> 
<%@ page import = "java.io.*" %> 
<%@ page import = "java.security.*" %> 
<%@ page import = "javax.crypto.*" %> 
<%@ page import = "javax.net.ssl.*" %> 
<%@ page import = "java.security.cert.X509Certificate" %> 
<%@ page import = "java.net.URL" %> 
<%@ page import = "org.json.simple.JSONObject" %> 
<%@ page import = "org.json.simple.parser.JSONParser" %> 
<%@ page import = "java.net.HttpURLConnection" %> 
<%@ page import = "javax.crypto.spec.SecretKeySpec" %> 
<%@ page import = "javax.crypto.spec.IvParameterSpec" %> 
<%@ page import = "java.text.SimpleDateFormat" %>

<%
	//01. PARAM date 수신
	Date currentDate = new Date();
	SimpleDateFormat fmt = new SimpleDateFormat("yyyyMMddHHmmss");
	String req_date = fmt.format(currentDate);
	SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMddHHmmss");
	String id       = request.getParameter("id");                               // 본인실명확인 회원사 아이디
    String srvNo    = request.getParameter("srvNo");                            // 본인확인 서비스번호
    String reqNum   = request.getParameter("reqNum");                           // 본인확인 요청번호
    String retUrl   = request.getParameter("retUrl");                           // 본인확인 결과수신 URL
	String certDate	= request.getParameter("certDate");                         // 본인확인 요청시간
	String certGb	= request.getParameter("certGb");                           // 본인확인 본인확인 인증수단
	String verSion	= request.getParameter("verSion");							// 본인확인 서비스 버전정보
	
	//02. 1차 암호화
    String cryptoToken = callCreateCryptoTokenAPI(req_date, reqNum);

    JSONParser parser = new JSONParser();
    JSONObject cryptoTokenJson = (JSONObject) parser.parse(cryptoToken);
    JSONObject dataBody = (JSONObject) cryptoTokenJson.get("dataBody");

    String crypto_token_id = (String) dataBody.get("crypto_token_id");
    String token_val = (String) dataBody.get("crypto_token");
	String reqInfo = getReqData(id, srvNo, reqNum, retUrl, certDate, certGb);

	
	

	String symmetricKey = createSymmetricKey(req_date, reqNum, token_val); 
    String key = symmetricKey.substring(0, 16); 
    String iv = symmetricKey.substring(symmetricKey.length() - 16, symmetricKey.length());// 데이터 암호화할  lnitail Vector
	
    reqInfo = getEncReqData(key, iv, reqInfo);

    String hmac_key = symmetricKey.substring(0, 32); // 암복호화 위변조 체크용req
    byte[] hmacSha256 = hmac256(hmac_key.getBytes(), reqInfo.getBytes()); 
    String integrity_value = Base64.getEncoder().encodeToString(hmacSha256);	

	// 3. 토큰 정보세팅
    
%>

<%!	
    public String createCryptoTokenUrl = "https://sciapi.siren24.com:52099/authentication/api/v1.0/common/crypto/token";
	public String access_token = "접근토큰";
	public String client_id = "비즈사이렌 인증키 관리 CLIENT ID ";
	
	// 암호화
	public String getEncReqData(String key, String iv, String reqData) throws Exception {
	    String req_info = "";
	    try {
	        SecretKey secureKey = new SecretKeySpec(key.getBytes(), "AES");
	        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
	        cipher.init(Cipher.ENCRYPT_MODE, secureKey, new IvParameterSpec(iv.getBytes()));
	        byte[] encrypted;
	        encrypted = cipher.doFinal(reqData.trim().getBytes());
	        req_info = Base64.getEncoder().encodeToString(encrypted);
	    } catch (Exception e) {
	    	System.out.println(String.format("(APICERT)(ERR) getEncReqData Exception : %s", e.getMessage()));
	        e.printStackTrace();
	        throw e;
	    }
	    return req_info;
	}
	
	public byte[] hmac256(byte[] secretKey,byte[] message) throws Exception{
	    byte[] hmac256 = null;
	    try{
	          Mac mac = Mac.getInstance("HmacSHA256");
	          SecretKeySpec sks = new SecretKeySpec(secretKey, "HmacSHA256");
	          mac.init(sks);
	          hmac256 = mac.doFinal(message);
	          return hmac256;
	    } catch(Exception e){
	    	System.out.println(String.format("(APICERT)(ERR) hmac256 Exception : %s", e.getMessage()));
	        e.printStackTrace();
	        throw e;
	    }
	}
	
	// createSymmetricKey 생성
	public String createSymmetricKey(String req_dtim, String req_no, String token_val) throws Exception {
	    String symmetricKey = "";
	    String value = req_dtim.trim() + req_no.trim() + token_val.trim();
	    MessageDigest md;
	    try {
	        md = MessageDigest.getInstance("SHA-256");
	        md.update(value.getBytes());
	        byte[] arrHashValue = md.digest();
	        symmetricKey = Base64.getEncoder().encodeToString(arrHashValue);
	    } catch (Exception e) {
	    	System.out.println(String.format("(APICERT)(ERR) createSymmetricKey Exception : %s", e.getMessage()));
	        e.printStackTrace();
	        throw e;
	    }
	    return symmetricKey;
	}
	
	// crypto tokenAPI 호출
	private String callCreateCryptoTokenAPI(String req_date, String req_no) throws Exception {

	    String authorization = "bearer " + access_token;
	
	    Map<String, String> requestPropertyMap = new HashMap<>();
	    requestPropertyMap.put("Content-Type", "application/json");
	    requestPropertyMap.put("Authorization", authorization);
	    HttpURLConnection connection = getURLConnection(createCryptoTokenUrl, "POST", requestPropertyMap, true, false);
	
	    JSONObject dataHeader = new JSONObject();
	    dataHeader.put("lang_code", "kr");
	    JSONObject dataBody = new JSONObject();
	    dataBody.put("client_id", client_id);
	    dataBody.put("req_date", req_date);
	    dataBody.put("req_no", req_no);
	    dataBody.put("enc_mode", "1");
	    JSONObject msgMap = new JSONObject();
	    msgMap.put("dataHeader", dataHeader);
	    msgMap.put("dataBody", dataBody);
	    String msg = msgMap.toJSONString();
	    if(send(connection.getOutputStream(), msg)) return "";
	    String receiveMsg = receive(connection.getInputStream());
	    return receiveMsg;
	}
	
	public Boolean send(OutputStream outputStream, String sendMsg) throws Exception {
	    Boolean isFail = true;
	    BufferedWriter bufferedWriter = null;
	    try {
	        bufferedWriter = new BufferedWriter(new OutputStreamWriter(outputStream, "utf-8"));
	        bufferedWriter.write(sendMsg);
	        bufferedWriter.flush();
	        isFail = false;
	    } catch (Exception e) {
	    	System.out.println(String.format("(APICERT)(ERR) send Exception : %s", e.getMessage()));
	        e.printStackTrace();
	        throw e;
	    } finally {
	        if (bufferedWriter != null) {
	            bufferedWriter.close();
	        }
	    }
	    return isFail;
	}
	
	public String receive(InputStream inputStream) throws Exception {
	    String receiveMsg = "";
	    BufferedReader bufferedReader = null;
	    try {
	        bufferedReader = new BufferedReader(new InputStreamReader(inputStream, "utf-8"));
	        StringBuilder stringBuilder = new StringBuilder();
	        String inputLine;
	        while ((inputLine = bufferedReader.readLine()) != null) {
	            stringBuilder.append(inputLine);
	        }
	        receiveMsg = stringBuilder.toString();
	    } catch (Exception e) {
	    	System.out.println(String.format("(APICERT)(ERR) receive Exception : %s", e.getMessage()));
	        e.printStackTrace();
	        throw e;
	    } finally {
	        if (bufferedReader != null) {
	            bufferedReader.close();
	        }
	    }
	    return receiveMsg;
	}
	
	public HttpURLConnection getURLConnection(String urlStr, String method, Map<String, String> requestPropertyMap, Boolean isNeedOutput, Boolean isHttps) throws Exception {
        try {
            URL url = new URL(urlStr);
            
            HttpURLConnection connection = (HttpURLConnection)url.openConnection();
            connection.setRequestMethod(method);
            
            connection.setDoInput(true);
            if (isNeedOutput) connection.setDoOutput(true);
            for (String key : requestPropertyMap.keySet()) {
            	connection.setRequestProperty(key, requestPropertyMap.get(key));
			}
            return connection;
        } catch (Exception e) {
        	System.out.println(String.format("(APICERT)(ERR) getURLConnection Exception : %s", e.getMessage()));
            e.printStackTrace();
            throw e;
        } finally {
        }
    }	

	public String getReqData(String id, String srvNo, String reqNum, String retUrl, String certDate, String certGb) {

    	JSONObject msgMap = new JSONObject();
        msgMap.put("id", id);
        msgMap.put("srvNo", srvNo);
        msgMap.put("reqNum", reqNum);
        msgMap.put("retUrl", retUrl);
        msgMap.put("certDate", certDate);
        msgMap.put("certGb", certGb);
        
        String reqData = msgMap.toJSONString();
        System.out.println("reqDate=>"+reqData);
        return reqData;
    }
	

%>
<meta http-equiv="X-UA-Compatible" content="IE=edge" />

<html>
<head>
<title>본인확인 서비스 Sample 화면</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta name="robots" content="noindex,nofollow" />
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

<script language=javascript>  
    var PCC_window; 

    function openPCCWindow(){ 
        var PCC_window = window.open('', 'PCCV3Window', 'width=400, height=630, resizable=1, scrollbars=no, status=0, titlebar=0, toolbar=0, left=300, top=200' );
      
		document.reqPCCForm.action = 'https://pcc.siren24.com/pcc_V3/jsp/pcc_V3_j10_v4.jsp'; 
        document.reqPCCForm.target = 'PCCV3Window';

		return true;
    }
</script>
</head>

<body bgcolor="#FFFFFF" topmargin=0 leftmargin=0 marginheight=0 marginwidth=0  background="/images/mem_back.gif" >
<center>
<br><br><br><br><br><br>
<span class="style1">본인확인서비스 요청화면 Sample입니다.</span><br>
<br><br>
<table cellpadding=1 cellspacing=1>    
    <tr>
        <td align=center>회원사아이디</td>
        <td align=left><%=id%></td>
    </tr>
    <tr>
        <td align=center>서비스번호</td>
        <td align=left><%=srvNo%></td>
    </tr>
    <tr>
        <td align=center>요청번호</td>
        <td align=left><%=reqNum%></td>
    </tr>
	<tr>
        <td align=center>인증구분</td>
        <td align=left><%=certGb%></td>
    </tr>
	<tr>
        <td align=center>요청시간</td>
        <td align=left><%=certDate%></td>
    </tr> 
    <tr>
        <td align=center>&nbsp</td>
        <td align=left>&nbsp</td>
    </tr>
    <tr width=100>
        <td align=center>요청정보(암호화)</td>
        <td align=left>
            <%=reqInfo%>
        </td>
    </tr>
</table>

<!-- 본인실명확인서비스 요청 form --------------------------->
<form name="reqPCCForm" method="post" action = "" onsubmit="return openPCCWindow()">
    <input type="hidden" name="crypto_token_id"    value = "<%=crypto_token_id%>">
    <input type="hidden" name="integrity_value"    value = "<%=integrity_value%>">
    <input type="hidden" name="reqInfo"    value = "<%=reqInfo%>">
    <input type="hidden" name="verSion"    value = "3">
    <input type="submit" value="본인확인서비스V3 요청" >	
</form>
<BR>
<BR>
<!--End 본인실명확인서비스 요청 form ----------------------->

<br>
<br>
  이 Sample화면은 본인확인서비스 요청화면 개발시 참고가 되도록 제공하고 있는 화면입니다.<br>
 <p style="color:red"><b> Sample페이지를 테스트로만 적용시키신 후 실제 운영사이트에 반영하실때는 샘플로 제공되고있는 파일명으로는 사용을 하지 말아주십시오. </b></p>
  <br>
</center>
</BODY>
</HTML>