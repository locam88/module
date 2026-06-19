package com.example.siren24;


public class PccRequestResult {

    private String cryptoTokenId;
    private String reqInfoEnc;
    private String integrityValue;
    private String key;
    private String iv;

    public String getCryptoTokenId() {
        return cryptoTokenId;
    }

    public void setCryptoTokenId(String cryptoTokenId) {
        this.cryptoTokenId = cryptoTokenId;
    }

    public String getReqInfoEnc() {
        return reqInfoEnc;
    }

    public void setReqInfoEnc(String reqInfoEnc) {
        this.reqInfoEnc = reqInfoEnc;
    }

    public String getIntegrityValue() {
        return integrityValue;
    }

    public void setIntegrityValue(String integrityValue) {
        this.integrityValue = integrityValue;
    }

    public String getKey() {
        return key;
    }

    public void setKey(String key) {
        this.key = key;
    }

    public String getIv() {
        return iv;
    }

    public void setIv(String iv) {
        this.iv = iv;
    }
}