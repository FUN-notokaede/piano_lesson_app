class Cluster{
  int width = 1160;
  int height = 770;
  float[][] map = new float[width][height];
  int area_size = 15;
  
  float[] stay_detection(ArrayList<Integer> a, ArrayList<Integer> b){
    float[] Mean_diff = new float[2];
    int stay = 0;
    float Mean_dif_x = 0;
    float Mean_dif_y = 0;
    float sum_x = 0;
    float sum_y = 0;
    float average_x = 0;
    float average_y = 0;
    
    //平均差分が小さければ
    if(a.size()>=10){
      for(int i = a.size()-1; i > a.size()-11; i--){
        sum_x = sum_x + a.get(i);
        sum_y = sum_y + b.get(i);
      }
      average_x = sum_x/10.;
      average_y = sum_y/10.;

      
      for(int i = a.size()-1; i > a.size()-11; i--){
        Mean_dif_x = sq(average_x- a.get(i));
        Mean_dif_y = sq(average_y- b.get(i));
      }
    }
    
    Mean_diff[0] = sqrt(Mean_dif_x);
    Mean_diff[1] = sqrt(Mean_dif_y);
    return Mean_diff;
  }
  
  int visualize_heat_map(ArrayList<Integer> a, ArrayList<Integer> b){
    int gaze = 0;
    
    map[a.get(a.size()-1)][b.get(b.size()-1)] = map[a.get(a.size()-1)][b.get(b.size()-1)] +1;
    for(int i = 0; i< float(width/area_size); i++){
      for(int j = 0; j< float(height/area_size); j++){
        int tmp = 0;
        
        //エリア内の値を計算
        //色塗り（gaze =1で注視していた、gaze = 0で注視していなかった）
        if(calc_sum(i*area_size, j*area_size, area_size)>2){fill(255, 0, 0, 30); gaze = 1;}
        else{fill(0,255,0, 30); gaze = 0;}
        rect(i*area_size, j*area_size, area_size, area_size);
     
     }
    }
    
    //マップの色を消していく操作
    for(int i = 0; i < width; i++){
      for(int j = 0; j< height; j++){
        map[i][j] = map[i][j] * 0.999;
      }
    }
    return gaze;
  }
  
  float calc_sum(int start_x, int start_y, int end){
    float sum = 0;
    
    for(int i =0; i<area_size; i++){
       for(int j =0; j<area_size; j++){
         sum = sum + map[start_x+i][start_y+j];
        }
    }
    return sum;
  }
}
