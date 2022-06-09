class gaze{
  float[] score_x;
  float[] score_y;
  ArrayList<ArrayList<Integer []>> EHS_list  = new ArrayList<ArrayList<Integer[]>>(); //EHS
  //int [][] EHS;//何音目〜何音目を一度に見ているのか
  gaze(float [] x, float[] y){
    score_x = x;
    score_y = y;
    int start = 0;
    int end = 0;
    
    //EHS = new int[score_x.length][2];
    ArrayList <Integer []> EHS = new ArrayList <Integer []>();//
    for(int i = 0; i<score_x.length; i++){
      Integer [] tmp_EHS = new Integer[2]; 
      if(0 <= i && i <= 5){
        start = 0;
        end =   5;
      }else if(score_x.length -11 <= start && start <= score_x.length - 5){
        start = i -5;
        end = score_x.length -1;
      }else{
        start = i -5;
        end = i + 5;
      }
      tmp_EHS[0] = start;
      tmp_EHS[1] = end;
      EHS.add(tmp_EHS);
    }
    EHS_list.add(EHS);
  }
  
  //領域内側であればtrue, 外であればfalse
  Boolean blind_touch_detection(int gaze_x, int gaze_y, int x_min, int x_lim, int y_min, int y_lim){
    if(x_min < gaze_x && gaze_x< x_lim && y_min < gaze_y && gaze_y < y_lim){
      return true;
    }
    return false;
  }
  
  //前回の推定位置と近いかどうか
  //とりあえずのルールとして、前回の位置+-5音以内であればtrueを返すようにしておく
  //これだと跳躍が発生しない前提
  //跳躍が発生した時には、跳躍先でローカルなDPマッチングをして
  //その結果がある程度保証される場合に、ブラインドタッチではなくて、跳躍のための視線移動だと考える
  
  float isBlind_touch(int pre_position, int position, int gaze_x, int gaze_y){
    float blind_touch = 0.0;
    int near_tone = search_nearest_note(gaze_x, gaze_y);
    
    blind_touch = 1.0/((pre_position+1 - near_tone) + 1.0); //距離+1の逆数 //分母が0にならないように 
    
    println(pre_position, near_tone, blind_touch,  "aaaaa");
    return blind_touch;
  }
  
  
  //EHSの大きさを更新する。
  void update_EHS(int gaze_x, int gaze_y, int pre_position, int position){
    //EHSリストの一番後ろの要素
    
    //新しく追加するためのArrayList
    ArrayList <Integer []> EHS = new ArrayList <Integer []>();//
    
    //最新-1型のEHSを元に、最新のEHSヲ作成する
    int counter = 0;
    for(int i = 0; i < EHS_list.get(EHS_list.size()-1).size();i++){
      int start = 0;
      int end = 0;
      Integer [] tmp_EHS = new Integer[2]; 
      

      if((EHS_list.get(EHS_list.size()-1).get(i)[0]>= pre_position) && (EHS_list.get(EHS_list.size()-1).get(i)[1]< position) && counter == 0){
        start = pre_position;
        end = position-1;
        tmp_EHS[0] = start;
        tmp_EHS[1] = end;
        EHS.add(tmp_EHS);
      }else{
        counter = 1;
      }
    }
    
  }
  //今の視点から最も近くにいる音符を出力
  int search_nearest_note(int gaze_x, int gaze_y){
    int arg_min = 0;
    float min = 2147483647;//
    
    for(int i = 0; i< score_x.length; i++){
      if(min > sqrt(pow(score_x[i] - gaze_x, 2) + pow(score_y[i] - gaze_y, 2))){
        arg_min = i; 
        min = sqrt(pow(score_x[i] - gaze_x, 2) + pow(score_y[i] - gaze_y, 2));
      }
    }
    return arg_min; //一番近くにある音符のindexを返す
  }
  
}
