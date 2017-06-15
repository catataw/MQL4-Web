//+------------------------------------------------------------------+
//|                                                          Web.mqh |
//|                                 Copyright 2017, Keisuke Iwabuchi |
//|                                         https://order-button.com |
//+------------------------------------------------------------------+
#property strict


/** muduleの2重読み込み防止用 */
#ifndef _LOAD_MODULE_WEB
#define _LOAD_MODULE_WEB


/**　@var int HTTP_TIMEOUT HTTP要求の時間制限[ミリ秒] */
#define HTTP_TIMEOUT 5000


/** import library files */
#import "stdlib.ex4"
   string ErrorDescription(int error_code);
#import


/** Webへリクエストを投げる際のパラメータ構造体 */
struct WebParameter
{
   string key;   // キー
   string value; // 値
};


/** Web連携処理 */
class Web
{
   public:
      static WebParameter params[];
      
      static bool request(const string  url,
                          const string  method,
                                char   &data[],
                                string &response);
      static void addParameter(const string key, const string value);
      static void resetPrameter(void);
      static bool get(string url, string &response);
      static bool post(string url, string &response);
};


/** @var WebParameter params リクエストパラメータを保存した構造体の配列 */
WebParameter Web::params[];


/**
 * webにアクセスする
 *
 * @param const string url アクセスするURL
 * @param const string method アクセスメソッド
 * @param char &data[] string型のパラメータをchar配列に変換したもの（POSTで使用する）
 * @param string &response 結果
 *
 * @return bool true:成功, false:失敗
 */
static bool Web::request(const string  url,
                         const string  method,
                               char   &data[],
                               string &response)
{
   if(IsTesting()) return(false);
   
   int    status_code;
   string headers;
   char   result[];
   uint   timeout = GetTickCount();
   
   status_code = WebRequest(method, 
                            url, 
                            NULL, 
                            NULL, 
                            HTTP_TIMEOUT, 
                            data, 
                            ArraySize(data), 
                            result, 
                            headers);
   
   if(status_code == -1) {
      if(GetTickCount() > timeout + HTTP_TIMEOUT) {
         Print("WebRequest get timeout");
      }
      else {
         Print(ErrorDescription(GetLastError()));
      }
      return(false);
   }
   
   response = CharArrayToString(result, 0, ArraySize(result), CP_UTF8);
   Web::resetPrameter();
   
   return(true);
}


/**
 * メンバ変数paramsにリクエストパラメータを追加する。
 * 指定したkeyのパラメータがすでに追加済みであれば、valueに上書きする。
 *
 * @params const string key 追加するパラメータの名前
 * @params const string value 追加するパラメータの値
 */
static void Web::addParameter(const string key, const string value)
{
   int size = ArraySize(Web::params);
   for(int i = 0; i < size; i++) {
      if(Web::params[i].key == key) {
         Web::params[i].value = value;
         return;
      }
   }
   
   int new_size = size + 1;
   ArrayResize(Web::params, new_size, 0);
   
   Web::params[size].key = key;
   Web::params[size].value = value;
}


/**
 * メンバ変数paramsをリセットする
 */
static void Web::resetPrameter(void)
{
   ArrayResize(Web::params, 0);
}


/**
 * GETでアクセスする
 *
 * @param string url アクセスするURL
 * @param string &response 結果
 *
 * @return bool true:成功, false:失敗
 */
static bool Web::get(string url, string &response)
{
   char data[];
   for(int i = 0; i < ArraySize(Web::params); i++) {
      if(i == 0) url += "?";
      else       url += "&";
      
      url += Web::params[i].key;
      url += "=";
      url += Web::params[i].value;
   }
   
   return(Web::request(url, "GET", data, response));
}


/**
 * POSTでアクセスする
 *
 * @param string url アクセスするURL
 * @param WebParameter &param[] パラメータ
 * @param string &response 結果
 *
 * @return bool true:成功, false:失敗
 */
static bool Web::post(string url, string &response)
{
   char data[];
   string post = "";
   for(int i = 0; i < ArraySize(Web::params); i++) {
      if(i != 0) post += "&";
      post += Web::params[i].key;
      post += "=";
      post += Web::params[i].value;
   }
   StringToCharArray(post, data);
   
   return(Web::request(url, "POST", data, response));
}


#endif 
