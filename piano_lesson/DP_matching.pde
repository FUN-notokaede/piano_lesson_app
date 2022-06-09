
class DP{
   //クラス変数
   int [] notes; //正解の音高列
   ArrayList<ArrayList<Float>> cost = new ArrayList<ArrayList<Float>>(); //コスト関数
   int pointer;//何回入力したか
   
   //コンストラクタでやること
   //DPマッチングを行う区間を指定する
   DP(int[] MIDI_numbers){
     notes = MIDI_numbers; //音高を代入
     ArrayList<Float> tmp_ = new ArrayList<Float>();//
     
     //costの初期化
     for(int i = 0; i < notes.length; i++){
       tmp_.add(0.0);
     }
    cost.add(tmp_);
   }
   
   //DPマッチング
   int search(int note){
     ArrayList<Float> tmp_cost = new ArrayList<Float>();//
     float tmp = 0.0; //仮コスト

     //楽曲長分だけ繰り返す。
     for(int i = 0; i<notes.length; i++){
       if(i == 0){
         tmp = 0.0;
       }else{
         tmp = cost.get(cost.size()-1).get(i-1);
       }
       if(notes[i] == note){
         //入力音と譜面上の音符が一致する時
         tmp_cost.add(tmp + 1);
       }else{
         tmp = tmp*0.8;
         tmp_cost.add(tmp);
       }
     }
     cost.add(tmp_cost);
     //一番大きなコストになるindexを返す
     return argmax(cost.get(cost.size()-1)).get(0);
   }
   
   
   //最大値を計算するargmax
   ArrayList<Integer> argmax(ArrayList<Float> list){
     float tmp_max = 0.0;//list.get(0);
     ArrayList<Integer> arg_max_index = new ArrayList<Integer>();//argmaxのindex
     //最大値の計算
     for(float i: list){
       if(i > tmp_max){tmp_max = i;}
     }
     //println(tmp_max);
     //最大値を持つindexの抽出
     for(int i = 0; i < list.size(); i++){
       if(list.get(i) >= tmp_max){arg_max_index.add(i);}
     }
     return arg_max_index;
   }
}
