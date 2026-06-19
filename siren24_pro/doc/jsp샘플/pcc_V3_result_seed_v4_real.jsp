<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="javax.crypto.*" %>
<%@ page import="javax.crypto.spec.SecretKeySpec, javax.crypto.spec.IvParameterSpec" %>
<%@ page import="java.security.*" %>
<%@ page import="javax.net.ssl.*" %>
<%@ page import="org.json.simple.JSONObject, org.json.simple.parser.JSONParser" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="javax.xml.bind.DatatypeConverter" %>
<html>
<head><title>본인확인 결과 수신 Sample - JSP</title></head>
<body>
<h3>[본인확인 결과 수신 Sample - JSP]</h3>
<%
    // ===== 1) 표준창 리턴 파라미터/세션 값 =====
 
    String reqcryptotokenid = request.getParameter("crypto_token_id") != null ? request.getParameter("crypto_token_id").trim() : null;

    // 표준창 호출 시 사용했던 세션 보관 값 

    String id     = "비즈사이렌 아이디";  // 회원사 ID



    // ===== 2) StoS용 암호화 토큰 발급 (createCryptoToken) =====
    Date now = new Date();
    SimpleDateFormat fmt = new SimpleDateFormat("yyyyMMddHHmmss");
    String req_date = fmt.format(now);
    String reqNo = makeReqNo(); 
    String tokenResp = null;
    try {
        tokenResp = callCreateCryptoTokenAPI(req_date, reqNo);
        System.out.println("[DEBUG] TokenResp: " + tokenResp);
    } catch (Exception e) {
        out.println("<p style='color:red'>토큰 API 호출 실패: " + e.getMessage() + "</p>");
        return;
    }

    JSONParser parser = new JSONParser();
    JSONObject tokenJson = (JSONObject) parser.parse(tokenResp);
    JSONObject tokenBody = (tokenJson != null) ? (JSONObject) tokenJson.get("dataBody") : null;
    if (tokenBody == null) {
        out.println("<p style='color:red'>토큰 API 응답 파싱 실패</p>");
        return;
    }

    String crypto_token_id = (String) tokenBody.get("crypto_token_id");
    String crypto_token    = (String) tokenBody.get("crypto_token");


    // ===== 3) StoS 요청용 대칭키 파생 & reqInfo 암호화 =====
    String symmetricKey = createSymmetricKey(req_date, reqNo, crypto_token); // Base64(SHA-256)
    String key = symmetricKey.substring(0, 16);
    String iv  = symmetricKey.substring(symmetricKey.length() - 16);

   
    String reqInfoPlain = getReqData(id, reqcryptotokenid);
    String reqInfoEnc   = getEncReqData(key, iv, reqInfoPlain);


    String integrity_value = base64Sha256(req_date + reqNo + crypto_token);

    // ===== 4) 인증결과API 호출 → RET_INFO 수신 =====
    String stosResp = null;
    try {
        stosResp = callServerToServerAPI(crypto_token_id, reqInfoEnc, integrity_value);
        out.println("<b>StoS Raw Response</b><br><pre>" + stosResp + "</pre><br>");
    } catch (Exception e) {
        out.println("<p style='color:red'>StoS 호출 실패: " + e.getMessage() + "</p>");
        return;
    }

    JSONObject stosJson = (JSONObject) parser.parse(stosResp);
    JSONObject stosBody = (stosJson != null) ? (JSONObject) stosJson.get("dataBody") : null;
    if (stosBody == null) {
        out.println("<p style='color:red'>StoS 응답 파싱 실패</p>");
        return;
    }

    String rsp_cd   = (String) stosBody.get("rsp_cd");
    String ret_info = (String) stosBody.get("RET_INFO");
    out.println("<b>StoS 결과</b><br>rsp_cd=" + rsp_cd + "<br>RET_INFO=" + ret_info + "<br><br>");

    if (!"P000".equals(rsp_cd)) {
        out.println("<p style='color:red'>StoS 오류 코드: " + rsp_cd + "</p>");
        return;
    }

    // ===== 5) RET_INFO 복호화 (표준창 때의 reqkey/reqiv 사용) =====
    try {
        SecretKeySpec reqKeySpec = new SecretKeySpec(key.getBytes("UTF-8"), "AES");
        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
        cipher.init(Cipher.DECRYPT_MODE, reqKeySpec, new IvParameterSpec(iv.getBytes("UTF-8")));

        byte[] enc = Base64.getDecoder().decode(ret_info);
        String resData = new String(cipher.doFinal(enc), StandardCharsets.UTF_8);

        JSONObject finalJson = (JSONObject) parser.parse(resData);
        out.println("<h3>복호화된 최종 결과</h3>");
        out.println("<pre>" + finalJson.toJSONString() + "</pre>");
    } catch (Exception e) {
        out.println("<p style='color:red'>RET_INFO 복호화 실패: " + e.getMessage() + "</p>");
    }
%>
</body>
</html>

<%!

public String createCryptoTokenUrl = "https://sciapi.siren24.com:52099/authentication/api/v1.0/common/crypto/token";
public String access_token = "접근토큰";
public String client_id = "비즈사이렌 인증키 관리 CLIENT ID ";

private String callCreateCryptoTokenAPI(String req_date, String req_no) throws Exception {

    String authorization = "bearer " + access_token;

    Map<String, String> headers = new LinkedHashMap<>();
    headers.put("Content-Type", "application/json; charset=utf-8");
    headers.put("Authorization", authorization);

    JSONObject dataHeader = new JSONObject();
    dataHeader.put("lang_code", "kr");

    JSONObject dataBody = new JSONObject();
    dataBody.put("client_id", client_id);
    dataBody.put("req_date", req_date);
    dataBody.put("req_no", req_no);
    dataBody.put("enc_mode", "1");

    JSONObject msg = new JSONObject();
    msg.put("dataHeader", dataHeader);
    msg.put("dataBody", dataBody);

    HttpURLConnection conn = getURLConnection(createCryptoTokenUrl, "POST", headers, true);
    send(conn.getOutputStream(), msg.toJSONString());
    return receive(conn.getInputStream());
}

// (B) StoS 호출
private String callServerToServerAPI(String crypto_token_id, String reqInfoEnc, String integrityValue) throws Exception {
    String url = "https://pcc.siren24.com/servlet/StoS";

    Map<String, String> headers = new LinkedHashMap<>();
    headers.put("Content-Type", "application/json; charset=utf-8");
   

    JSONObject dataHeader = new JSONObject();
    dataHeader.put("CNTY_CD", "kr");
    dataHeader.put("TRAN_ID", "비즈사이렌 로그인 아이디"); 

    JSONObject dataBody = new JSONObject();
    dataBody.put("crypto_token_id", crypto_token_id);
    dataBody.put("reqInfo", reqInfoEnc);
    dataBody.put("integrity_value", integrityValue); 

    JSONObject msg = new JSONObject();
    msg.put("dataHeader", dataHeader);
    msg.put("dataBody", dataBody);

    HttpURLConnection conn = getURLConnection(url, "POST", headers, true);
    send(conn.getOutputStream(), msg.toJSONString());
    return receive(conn.getInputStream());
}


private HttpURLConnection getURLConnection(String urlStr, String method, Map<String,String> headers, boolean doOutput) throws Exception {
    URL url = new URL(urlStr);
    URLConnection uc = url.openConnection();
    if (uc instanceof HttpsURLConnection) {
        HttpsURLConnection h = (HttpsURLConnection) uc;
        h.setSSLSocketFactory(((SSLSocketFactory) SSLSocketFactory.getDefault()));
        h.setHostnameVerifier(new HostnameVerifier() {
            public boolean verify(String s, SSLSession sslSession) { return true; } 
        });
        h.setRequestMethod(method);
        h.setDoInput(true);
        h.setDoOutput(doOutput);
        for (Map.Entry<String,String> e : headers.entrySet()) h.setRequestProperty(e.getKey(), e.getValue());
        return h;
    } else {
        HttpURLConnection h = (HttpURLConnection) uc;
        h.setRequestMethod(method);
        h.setDoInput(true);
        h.setDoOutput(doOutput);
        for (Map.Entry<String,String> e : headers.entrySet()) h.setRequestProperty(e.getKey(), e.getValue());
        return h;
    }
}

// (D) 전송/수신 - 성공/실패 리턴값 없이, 실패 시 예외
private void send(OutputStream os, String msg) throws Exception {
    try (BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(os, StandardCharsets.UTF_8))) {
        bw.write(msg);
        bw.flush();
    }
}
private String receive(InputStream is) throws Exception {
    StringBuilder sb = new StringBuilder();
    try (BufferedReader br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))) {
        String line;
        while ((line = br.readLine()) != null) sb.append(line);
    }
    return sb.toString();
}

// (E) 대칭키 파생/암복호/무결성
public String createSymmetricKey(String req_dtim, String req_no, String token_val) throws Exception {
    String seed = (req_dtim==null?"":req_dtim) + (req_no==null?"":req_no) + (token_val==null?"":token_val);
    MessageDigest md = MessageDigest.getInstance("SHA-256");
    byte[] digest = md.digest(seed.getBytes(StandardCharsets.UTF_8));
    return Base64.getEncoder().encodeToString(digest); // Base64(SHA-256)
}
public String base64Sha256(String s) throws Exception {
    MessageDigest md = MessageDigest.getInstance("SHA-256");
    byte[] d = md.digest(s.getBytes(StandardCharsets.UTF_8));
    return Base64.getEncoder().encodeToString(d);
}
public String getEncReqData(String key, String iv, String reqData) throws Exception {
    SecretKeySpec sk = new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "AES");
    Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
    cipher.init(Cipher.ENCRYPT_MODE, sk, new IvParameterSpec(iv.getBytes(StandardCharsets.UTF_8)));
    byte[] enc = cipher.doFinal(reqData.getBytes(StandardCharsets.UTF_8));
    return Base64.getEncoder().encodeToString(enc);
}

public String getReqData(String id, String reqcryptotokenid) {
    JSONObject o = new JSONObject();
    o.put("id", id);
    o.put("reqcryptotokenid", reqcryptotokenid);
    return o.toJSONString();
}

public String makeReqNo() {
    return String.valueOf(System.currentTimeMillis()).substring(3); 
}
%>