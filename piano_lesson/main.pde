import rwmidi.*; //<>//
import processing.serial.*;


String date = year()+","+month()+","+day();
String filename = "output/今日のわんこ"+date;

//画面サイズ
int width = 1160;
int height = 770;

//データの書き出し
PrintWriter file; 
PrintWriter heat_map;

//midi
MidiOutput output;
MidiInput input;

int notePlayed; //MIDIノートナンバ
int noteVelocity; //MIDIベロシティ

//視線
gaze gaze_tmp;
int near_tone_by_gaze;
int gaze; //注視していたか、していなかったか
float[] sd  = new float[2]; //注視していたか、していなかったか

//ブラインドタッチ判断用の領域（仮）
int area_x_min = 100;
int area_x_lim = 200;
int area_y_min = 100;
int area_y_lim = 200;


//楽譜
score test_score;
float percentage = 0.6; //楽譜の縮尺


//楽曲の音高リスト
int[] MIDI_numbers = {
69, 71, 69, 67, 69, 76, 67, 74, 67, 72, 64, 67, 
72, 71, 71, 69, 71, 72, 67, 69, 67, 66, 67, 
76, 67, 74, 67, 72, 64, 67, 72, 71, 71, 69, 
71, 72, 72, 71, 76, 76, 71, 72, 69, 68, 69, 
71, 68, 69, 71, 69, 74, 74, 66, 67, 67, 69, 
62, 71, 71, 72, 69, 74, 74, 76, 73, 74, 74, 
79, 77, 76, 67, 74, 67, 72, 64, 67, 72, 71, 
71, 69, 71, 72, 67, 69, 67, 66, 67, 76, 67, 
79, 67, 77, 69, 79, 77, 76, 74, 72, 72, 72, 
71, 69, 71, 72};
int MIDI_on = 0;

DP global_dp; //楽曲全体に対して楽譜追跡するためのDPマッチング

//推定位置
ArrayList<Integer> estimated_position = new ArrayList<Integer>();
//estimated_position.add(1); //追加方法
//estimated_position.get(index); //値の取得方法
////estimated_position.size(); //長さを取得

ArrayList<Integer> estimated_position_for_EHS = new ArrayList<Integer>();

//打鍵時なのか、離鍵時なのか
ArrayList<Integer> MIDI_on_list = new ArrayList<Integer>();

//ブラインドタッチしているかどうか
float blind_touch;

//パラメータ
float sisen_no_shinraido = 0.3;

//視線の移動平均を算出
ArrayList<Integer> gaze_x_list = new ArrayList<Integer>(); 
ArrayList<Integer> gaze_y_list = new ArrayList<Integer>(); 

Cluster c;

void setup(){
  frameRate(100);
  //保存先
  file = createWriter(filename+"test.csv");
  file.println("時刻(ms), 視線位置_x, 視線位置_y, MIDI_note_Number, MIDI_note_Velocity, MIDI_on_off, 推定位置, 滞留度_x, 滞留度_y");
  //視線に関するインスタンス生成
  test_score = new score(percentage);
  gaze_tmp = new gaze(test_score.score_x, test_score.score_y);
  size(1160, 770);
  
  //MIDIの初期設定
  input = RWMidi.getInputDevices()[0].createInput(this);
  output = RWMidi.getOutputDevices()[0].createOutput();
  println("Input: " + input.getName());
  println("Output: " + output.getName());
  
  //推定位置の初期化
  estimated_position.add(0);
  
  //楽譜追跡のインスタンス
  global_dp = new DP(MIDI_numbers);
  
  //ヒートマップを作るための
  c = new Cluster();
}

//打鍵情報の獲得（ノートナンバー and velocity)

//離鍵時
void noteOffReceived(Note note) {
  notePlayed = note.getPitch();
  noteVelocity = note.getVelocity();
  MIDI_on = 0; //ノートオフ
}

//打鍵時
void noteOnReceived(Note note) {
  MIDI_on = 1; //ノートオン
  notePlayed = note.getPitch();
  noteVelocity = note.getVelocity();

  //ローカル位置のDPマッチング
  int[] local_area;//startとendが入っている
  
  //視線に近いエリア
  local_area = local_serch_area(MIDI_numbers, near_tone_by_gaze);
  
  //グローバルなサーチ
  int tmp = global_dp.search(notePlayed);

  //ブラインドタッチかどうか
  blind_touch = gaze_tmp.isBlind_touch(estimated_position.get(estimated_position.size()-1), tmp, mouseX, mouseY);
  //println(blind_touch);
  //global DP とlocal_DPを統合
  float [] marged_list = new float[global_dp.cost.get(global_dp.cost.size()-1).size()];
  sisen_no_shinraido = 0.3;
  for(int i = 0; i<global_dp.cost.get(global_dp.cost.size()-1).size(); i++){
    if(local_area[0] <= i && i<= local_area[1]){
    //global DP + 視線の信頼度*ブラインドタッチか否か*local_DP
    marged_list[i] = global_dp.cost.get(global_dp.cost.size()-1).get(i) 
                   + blind_touch*sisen_no_shinraido*(global_dp.cost.get(global_dp.cost.size()-1).get(i));
    }else{marged_list[i] = global_dp.cost.get(global_dp.cost.size()-1).get(i);}
  }
  
  ArrayList<Integer> argmax;
  argmax = argmax(marged_list);
  estimated_position.add(argmax.get(0)); //これが推定された値（1つのみ）
}

//擬似的なEHS、とりあえず音符 +-5音分
int[] local_serch_area(int[] MIDI_numbers, int start){
  int range = 0;
  int [] start_end = new int[2];
  if(0 <= start && start < 5){
    start = 0;
    range = start + 5;
  }else if(103 -10 < start && start <= 103 - 5){
    start = start -5;
    range = 103;
  }else{
    start = start -5;
    range = start + 5;
  }
  
  start_end[0] = start;
  start_end[1] = range;
  return start_end;
}

//最大値の計算
ArrayList<Integer> argmax(float[] list){
  float tmp_max = 0.0;//list.get(0);
  ArrayList<Integer> arg_max_index = new ArrayList<Integer>();//argmaxのindex
  //最大値の計算
  for(float i: list){
    if(i > tmp_max){tmp_max = i;}
  }
  //最大値を持つindexの抽出
  for(int i = 0; i < list.length; i++){
    if(list[i] >= tmp_max){arg_max_index.add(i);}
  }
  return arg_max_index;
}

//ログファイルの出力
void keyPressed(){
  if(key == ENTER){
    file.flush();
    file.close();
    
    heat_map = createWriter(filename+"heat_map.csv");
    for(int i = 0; i< c.width; i++){
      for(int j = 0; j<c.height; j++){
        heat_map.print(c.map[i][j]+",");
      }
      heat_map.println("");
    }
    exit();
  }
}


//メイン関数
void draw(){
  int ms = millis();
  background(255, 255, 200);
  image(test_score.img, 0, 0,(test_score.img.width*percentage), (test_score.img.height*percentage));

  //ブラインドタッチかどうか判定する関数 boolean
  near_tone_by_gaze = gaze_tmp.search_nearest_note(mouseX, mouseY); //視線が一番近い音
  
  if(blind_touch >= 0.1){fill(0, 128, 128);}
  else{fill(255, 255, 255);}
  rect(51, 710, 200, 50);
  text("blind_tourch", 51, 710);
  rect(test_score.score_x[estimated_position.get(estimated_position.size()-1)]-10, test_score.score_y[estimated_position.get(estimated_position.size()-1)]-50, 10, 70);//見ている音
  
  //対応するEHS
  //print(near_tone_by_gaze);
  float left_x;
  float left_y;
  float right_x;
  float right_y;
  
  //percentage 60%仕様
  if(near_tone_by_gaze <=34){left_y =40; right_y = 40;}
  else if(35<= near_tone_by_gaze && near_tone_by_gaze <= 64){left_y =237; right_y = 40;}
  else if(65<= near_tone_by_gaze && near_tone_by_gaze <= 102){left_y =435; right_y = 40;}
  else{left_y =630; right_y = 40;};
  //println(gaze_tmp.EHS_list.get(0).get(0));


  gaze_x_list.add(mouseX);
  gaze_y_list.add(mouseY);
  
  gaze = c.visualize_heat_map(gaze_x_list, gaze_y_list);
  sd = c.stay_detection(gaze_x_list, gaze_y_list);
  //鍵盤のon off
  MIDI_on_list.add(MIDI_on);
  
  estimated_position_for_EHS.add(estimated_position.get(estimated_position.size()-1));
  
  //現在の状況をプリントする
  //時刻()、視線位置、打鍵音、ベロシティ、MIDI on off、推定位置、滞留度（ヒートマップ）
  //file.println("時刻, 視線位置_x, 視線位置_y, MIDI_note_Number, MIDI_note_Velocity, MIDI_on_off, 推定位置, 滞留度(過去nフレームにおけるx, yの移動平均));
  file.println(ms +"," +mouseX+","+mouseY+","+notePlayed+","+noteVelocity+","+MIDI_on_list.get(MIDI_on_list.size()-1)+","+estimated_position.get(estimated_position.size()- 1)+","+sd[0]+","+sd[1]);
  
  
  
  //視線の位置を表示
  fill(10, 10, 40, 30);
  stroke(10, 10, 40, 30);
  for(int i = 0; i<gaze_x_list.size(); i++){
    if(i > gaze_x_list.size()-10){
      ellipse(gaze_x_list.get(i), gaze_y_list.get(i), 20, 20);
    }
  }
}
