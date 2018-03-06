//
//  SelectFriendViewController.swift
//  HowlTalk
//
//  Created by 유명식 on 2018. 1. 23..
//  Copyright © 2018년 swift. All rights reserved.
//

import UIKit
import Firebase
import BEMCheckBox

class SelectFriendViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,BEMCheckBoxDelegate {
    var users = Dictionary<String,Bool>()
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var tableview: UITableView!
    var array : [UserModel] = []
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var view = tableView.dequeueReusableCell(withIdentifier: "SelectFriendCell", for: indexPath) as! SelectFriendCell
        view.labelName.text = array[indexPath.row].userName
        view.imageviewProfile.kf.setImage(with: URL(string:array[indexPath.row].profileImageUrl!))
        view.checkbox.delegate = self
        view.checkbox.tag = indexPath.row
        
        return view
    }
    func didTap(_ checkBox: BEMCheckBox) {
        //체크박스가 체크 됬을때 발생하는 이벤트
        if(checkBox.on){
        users[self.array[checkBox.tag].uid!] = true
            
            //체크박스가 체크가 해제 됬을때 발생하는 이벤트
        }else{
            users.removeValue(forKey: self.array[checkBox.tag].uid!)
            
        }
    }
    func createRoom(){
        var myUid = Auth.auth().currentUser?.uid
        users[myUid!] = true
        let nsDic = users as! NSDictionary
        
        Database.database().reference().child("chatrooms").childByAutoId().child("users").setValue(nsDic)
        
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        Database.database().reference().child("users").observe(DataEventType.value, with: { (snapshot) in
            
            
            self.array.removeAll()
            
            let myUid = Auth.auth().currentUser?.uid
            
            for child in snapshot.children{
                let fchild = child as! DataSnapshot
                let userModel = UserModel()
                userModel.setValuesForKeys(fchild.value as! [String : Any])
                
                
                if(userModel.uid == myUid){
                    continue
                }
                
                
                self.array.append(userModel)
                
            }
            
            DispatchQueue.main.async {
                self.tableview.reloadData();
            }
        })
        
        button.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
class SelectFriendCell : UITableViewCell{
    
    @IBOutlet weak var checkbox: BEMCheckBox!
    @IBOutlet weak var imageviewProfile: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    
}
