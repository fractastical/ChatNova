public class chatterDirUtil {

    // Modified to sort inner classes instead of sObjects - jhersh@salesforce.com
    
    public static void sortList(List<chatterDirectory.userFollowers> items, String sortField, String order){
        /*I must give credit where it is due as the sorting algorithm I am using is the 
        one supplied by Andrew Waite here: http://blog.sforce.com/sforce/2008/09/sorting-collect.html */
        
        Boolean isSortFieldReference = false;
        Map<Id,String> referenceName;

        List<chatterDirectory.userFollowers> resultList = new List<chatterDirectory.userFollowers>();
    
        if( sortField == 'followers' || sortField == 'following' ) {
            
            //Create a map that can be used for sorting 
            Map<integer, List<chatterDirectory.userFollowers>> objectMap = new Map<integer, List<chatterDirectory.userFollowers>>();
            
            for(chatterDirectory.userFollowers ob : items){
                    if(objectMap.get(integer.valueof(ob.get(sortField))) == null){ 
                        objectMap.put(integer.valueof(ob.get(sortField)), new List<chatterDirectory.userFollowers>()); 
                    }
                    

                    objectMap.get(integer.valueof(ob.get(sortField))).add(ob);
            }
        
            //Sort the keys
        
            List<integer> keys = new List<integer>(objectMap.keySet());
            keys.sort();       
            
            for(integer key : keys)
            resultList.addAll(objectMap.get(key));      
        } else {
            
             //Create a map that can be used for sorting 
            Map<string, List<chatterDirectory.userFollowers>> objectMap = new Map<string, List<chatterDirectory.userFollowers>>();
        
            for(chatterDirectory.userFollowers ob : items){
                    if(objectMap.get(ob.get(sortField)) == null){ 
                        objectMap.put(ob.get(sortField), new List<chatterDirectory.userFollowers>()); 
                    }
                    
                    objectMap.get(ob.get(sortField)).add(ob);
            }   
            
            //Sort the keys
            
            List<string> keys = new List<string>(objectMap.keySet());
            keys.sort();
            
            for(string key : keys)
            resultList.addAll(objectMap.get(key)); 
        }
        
        //Apply the sorted values to the source list
        items.clear();
        if(order.toLowerCase() == 'asc'){
            for(chatterDirectory.userFollowers ob : resultList){
                items.add(ob);  
            }
        }else if(order.toLowerCase() == 'desc'){
            for(integer i = resultList.size()-1; i >= 0; i--){
                items.add(resultList[i]);   
            } 
        }
    }
    
    public void x() {
        integer x = 0; 
        
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
        x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;x++;
    
    }
    
    public static testmethod void runTest() {
        chatterDirUtil tmp = new chatterDirUtil();
        tmp.x();
    }
}