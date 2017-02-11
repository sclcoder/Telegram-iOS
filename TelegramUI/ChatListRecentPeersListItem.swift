import Foundation
import UIKit
import AsyncDisplayKit
import Postbox
import Display
import SwiftSignalKit
import TelegramCore

class ChatListRecentPeersListItem: ListViewItem {
    let account: Account
    let peers: [Peer]
    let peerSelected: (Peer) -> Void
    
    let header: ListViewItemHeader?
    
    init(account: Account, peers: [Peer], peerSelected: @escaping (Peer) -> Void) {
        self.account = account
        self.peers = peers
        self.peerSelected = peerSelected
        self.header = nil
    }
    
    func nodeConfiguredForWidth(async: @escaping (@escaping () -> Void) -> Void, width: CGFloat, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, () -> Void)) -> Void) {
        async {
            let node = ChatListRecentPeersListItemNode()
            let makeLayout = node.asyncLayout()
            let (nodeLayout, nodeApply) = makeLayout(self, width, nextItem != nil)
            node.contentSize = nodeLayout.contentSize
            node.insets = nodeLayout.insets
            
            completion(node, nodeApply)
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: ListViewItemNode, width: CGFloat, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping () -> Void) -> Void) {
        if let node = node as? ChatListRecentPeersListItemNode {
            Queue.mainQueue().async {
                let layout = node.asyncLayout()
                async {
                    let (nodeLayout, apply) = layout(self, width, nextItem != nil)
                    Queue.mainQueue().async {
                        completion(nodeLayout, {
                            apply().1()
                        })
                    }
                }
            }
        }
    }
}

private let separatorHeight = 1.0 / UIScreen.main.scale

class ChatListRecentPeersListItemNode: ListViewItemNode {
    private let backgroundNode: ASDisplayNode
    private let separatorNode: ASDisplayNode
    private var peersNode: ChatListSearchRecentPeersNode?
    
    private var item: ChatListRecentPeersListItem?
    
    required init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.backgroundColor = .white
        self.backgroundNode.isLayerBacked = true
        
        self.separatorNode = ASDisplayNode()
        self.separatorNode.backgroundColor = UIColor(0xc8c7cc)
        self.separatorNode.isLayerBacked = true
        
        super.init(layerBacked: false, dynamicBounce: false)
        
        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.separatorNode)
    }
    
    override func layoutForWidth(_ width: CGFloat, item: ListViewItem, previousItem: ListViewItem?, nextItem: ListViewItem?) {
        if let item = self.item {
            let makeLayout = self.asyncLayout()
            let (nodeLayout, nodeApply) = makeLayout(item, width, nextItem == nil)
            self.contentSize = nodeLayout.contentSize
            self.insets = nodeLayout.insets
            let _ = nodeApply()
        }
    }
    
    func asyncLayout() -> (_ item: ChatListRecentPeersListItem, _ width: CGFloat, _ last: Bool) -> (ListViewItemNodeLayout, () -> (Signal<Void, NoError>?, () -> Void)) {
        return { [weak self] item, width, last in
            let nodeLayout = ListViewItemNodeLayout(contentSize: CGSize(width: width, height: 130.0), insets: UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0))
            
            return (nodeLayout, { [weak self] in
                return (nil, {
                    if let strongSelf = self {
                        strongSelf.item = item
                        
                        let peersNode: ChatListSearchRecentPeersNode
                        if let currentPeersNode = strongSelf.peersNode {
                            peersNode = currentPeersNode
                        } else {
                            peersNode = ChatListSearchRecentPeersNode(account: item.account, peerSelected: { peer in
                                self?.item?.peerSelected(peer)
                            })
                            strongSelf.peersNode = peersNode
                            strongSelf.addSubnode(peersNode)
                        }
                        
                        let separatorHeight = UIScreenPixel
                        
                        peersNode.frame = CGRect(origin: CGPoint(), size: nodeLayout.contentSize)
                        
                        strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: nodeLayout.contentSize.width, height: nodeLayout.contentSize.height))
                        strongSelf.separatorNode.frame = CGRect(origin: CGPoint(x: 0.0, y: nodeLayout.contentSize.height - separatorHeight), size: CGSize(width: nodeLayout.size.width, height: separatorHeight))
                        strongSelf.separatorNode.isHidden = true
                    }
                })
            })
        }
    }
    
    override func animateInsertion(_ currentTimestamp: Double, duration: Double, short: Bool) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: duration * 0.5)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: duration * 0.5, removeOnCompletion: false)
    }
    
    override public func header() -> ListViewItemHeader? {
        if let item = self.item {
            return item.header
        } else {
            return nil
        }
    }
}
