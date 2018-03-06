//
//  GroupChatRoomViewController.swift
//  HowlTalk
//
//  Created by 유명식 on 2018. 2. 7..
//  Copyright © 2018년 swift. All rights reserved.
//

import UIKit
import Firebase
import Alamofire

class GroupChatRoomViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
   
    
    @IBOutlet weak var button_send: UIButton!
    
    @IBOutlet weak var textfield_message: UITextField!
    
    @IBOutlet weak var tableview: UITableView!
    var destinationRoom : String?
    var uid : String?
    
    var databaseRef : DatabaseReference?
    var observe : UInt?
    var comments : [ChatModel.Comment] = []
    var users : [String:AnyObject]?
    var peopleCount :Int?
    override func viewDidLoad() {
        super.viewDidLoad()
        uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            self.users = datasnapshot.value as! [String:AnyObject]
            
        })
        button_send.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        // Do any additional setup after loading the view.
        getMessageList()
    }
    func sendMessage(){
        
        let value : Dictionary<String,Any> = [
            "uid": uid!,
            "message": textfield_message.text!,
            "timestamp" : ServerValue.timestamp()
        ]
        Database.database().reference().child("chatrooms").child(destinationRoom!).child("comments").childByAutoId().setValue(value) { (err, ref) in
            
            Database.database().reference().child("chatrooms").child(self.destinationRoom!).child("users").observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
                let dic = datasnapshot.value as! [String:Any]
                
                for item in dic.keys{
                    if(item == self.uid){
                        continue
                    }
                    let user = self.users![item]
                    self.sendGcm(pushToken: user!["pushToken"] as! String)
                }
                self.textfield_message.text = ""
            })
        }
        
    }
    
    func sendGcm(pushToken : String?){
        
        let url = "https://gcm-http.googleapis.com/gcm/send"
        
        let header : HTTPHeaders = [
            "Content-Type":"application/json",
            "Authorization":"key=AIzaSyDNFs9vhpZQzQ3VeMXojsAJIId2Z7aj_Xk"
            
            
        ]
        
        let userName = Auth.auth().currentUser?.displayName
        
        var notificationModel = NotificationModel()
        notificationModel.to = pushToken!
        notificationModel.notification.title = userName
        notificationModel.notification.text = textfield_message.text
        notificationModel.data.title = userName
        notificationModel.data.text = textfield_message.text
        
        
        let params = notificationModel.toJSON()
        
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
            print(response.result.value)
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(self.comments[indexPath.row].uid == uid){
            let view = tableView.dequeueReusableCell(withIdentifier: "MyMessageCell", for: indexPath) as! MyMessageCell
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0
            
            if let time = self.comments[indexPath.row].timestamp{
                view.label_timestamp.text = time.toDayTime
            }
            
            
            setReadCount(label: view.label_read_counter, position: indexPath.row)
            
            return view
            
        }else{
            let destinationUser = users![self.comments[indexPath.row].uid!]
            let view = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMessageCell
            view.label_name.text = destinationUser!["userName"] as! String
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0;
            let imageUrl = destinationUser!["profileImageUrl"] as! String
            let url = URL(string:(imageUrl))
            view.imageview_profile.layer.cornerRadius = view.imageview_profile.frame.width/2
            view.imageview_profile.clipsToBounds = true
            view.imageview_profile.kf.setImage(with: url)
            
            if let time = self.comments[indexPath.row].timestamp{
                view.label_timestamp.text = time.toDayTime
            }
            
            
            setReadCount(label: view.label_read_counter, position: indexPath.row)
            return view
            
        }
        
        
        
        
        
        return UITableViewCell()
        
    }
    
    func setReadCount(label:UILabel?, position: Int?){
        let readCount = self.comments[position!].readUsers.count
        
        if(peopleCount == nil){
            
            
            Database.database().reference().child("chatrooms").child(destinationRoom!).child("users").observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
                
                let dic = datasnapshot.value as! [String:Any]
                self.peopleCount = dic.count
                let noReadCount = self.peopleCount! - readCount
                
                if(noReadCount > 0){
                    label?.isHidden = false
                    label?.text = String(noReadCount)
                }else{
                    label?.isHidden = true
                    
                }
            })
        }else{
            let noReadCount = peopleCount! - readCount
            
            if(noReadCount > 0){
                label?.isHidden = false
                label?.text = String(noReadCount)
            }else{
                label?.isHidden = true
                
            }
        }
        
        
        
    }
    func getMessageList(){
        databaseRef = Database.database().reference().child("chatrooms").child(self.destinationRoom!).child("comments")
        observe = databaseRef?.observe(DataEventType.value, with: { (datasnapshot) in
            self.comments.removeAll()
            var readUserDic : Dictionary<String,AnyObject> = [:]
            for item in datasnapshot.children.allObjects as! [DataSnapshot]{
                let key = item.key as String
                let comment = ChatModel.Comment(JSON: item.value as! [String:AnyObject])
                let comment_motify = ChatModel.Comment(JSON: item.value as! [String:AnyObject])
                comment_motify?.readUsers[self.uid!] = true
                readUserDic[key] = comment_motify?.toJSON() as! NSDictionary
                self.comments.append(comment!)
            }
            
            let nsDic = readUserDic as NSDictionary
            
            if(self.comments.last?.readUsers.keys == nil){
                return
            }
            
            if(!(self.comments.last?.readUsers.keys.contains(self.uid!))!){
                
                
                datasnapshot.ref.updateChildValues(nsDic as! [AnyHashable : Any], withCompletionBlock: { (err, ref) in
                    
                    self.tableview.reloadData()
                    
                    if self.comments.count > 0{
                        self.tableview.scrollToRow(at: IndexPath(item:self.comments.count - 1,section:0), at: UITableViewScrollPosition.bottom, animated: false)
                        
                    }
                    
                })
            }else{
                self.tableview.reloadData()
                
                if self.comments.count > 0{
                    self.tableview.scrollToRow(at: IndexPath(item:self.comments.count - 1,section:0), at: UITableViewScrollPosition.bottom, animated: false)
                    
                }
            }
            
            
            
            
            
        })
        
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
