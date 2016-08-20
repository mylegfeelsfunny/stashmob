//
//  RemoteContact.swift
//  StashMob
//
//  Created by Scott Jones on 8/20/16.
//  Copyright © 2016 Scott Jones. All rights reserved.
//

import Foundation
import StashMobModel

let title = NSLocalizedString("YO! Check out this wacky place!", comment: "Email Title : text")
let subMessage = NSLocalizedString("Follow this link to see what I'm up to.\n(Make sure you have StashMob on your phone.)", comment: "RemoteContact message : text")

enum  Deliverable {
    case Both
    case Email
    case Text
}

extension RemoteContact {
    
    func saveRawImage(data:NSData) {
        guard let imgN = imageName else { return }
        NSFileManager.defaultManager().saveImageNamed(imgN, ext:"jpg", data:data)
    }
    
    func getImage()->UIImage {
        guard let imgN = imageName else { return UIImage(named: "defaultavatar")! }
        guard let img = NSFileManager.defaultManager().getImageNamed(imgN, ext:"jpg") else {
            return UIImage(named: "defaultavatar")!
        }
        return img
    }
   
    var fullName:String {
        if let f = firstName, l = lastName {
            return "\(f) \(l)"
        } else if let f = firstName {
            return f
        } else if let l = lastName {
            return l
        }
        return ""
    }
    
    func deepLinkUrlMessage(placeId:String)->String {
        var emailhash = ""
        var phoneHash = ""
        if let e = email {
            emailhash = "e=\(e)"
        }
        if let pn = phoneNumber {
            phoneHash   = "p=\(pn)"
        }
        return "\(subMessage)\n\n\(NSBundle.mainBundle().deepLinkUrl)://\(placeId)?\(emailhash)&\(phoneHash)"
    }
    
    func emailInfo(placeId:String)->EmailInfo {
        guard let eml = email else { fatalError("RemoteContact needs the email to create email info") }
        let info = EmailInfo(
            titleString: title
            ,messageString: deepLinkUrlMessage(placeId)
            ,toRecipentsArray:[eml]
        )
        return info
    }
    
    func textInfo(placeId:String)->TextInfo {
        guard let pn = phoneNumber else { fatalError("RemoteContact needs the phone to create text info") }
        let info = TextInfo(
            messageString: deepLinkUrlMessage(placeId)
            ,toRecipentsArray:[pn]
        )
        return info
    }
    
    var options:Deliverable {
        if let _ = email, _ = phoneNumber {
            return .Both
        } else if let _ = email {
            return .Email
        } else if let _ = phoneNumber{
            return .Text
        }
        fatalError("The Remote user needs something to contact you by")
    }
    
    
}