//
//  ViewController.swift
//  EverydayTodo
//
//  Created by Jeyaganthan on 2020/12/14.
//

import UIKit
import CoreData
import Lottie

class TodoViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    let todoListViewModel = TodoViewModel()
    let profileViewModel = ProfileViewModel()
    let animationView = AnimationView()

    override func viewDidLoad() {
        super.viewDidLoad()
        todoListViewModel.loadTasks()
        profileViewModel.fetchProfile()
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout{
            layout.sectionHeadersPinToVisibleBounds = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if Core.shared.isNewUser() {
            // show onboarding
            let sb = UIStoryboard(name: "Welcome", bundle: nil)
            let vc = sb.instantiateViewController(identifier: "welcome") as! WelcomeViewController
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true, completion: nil)
        }
    }
}

extension TodoViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return todoListViewModel.todos.count  //+ 1 // add + 1 for AddCell
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TodoCell", for: indexPath) as? TodoCollectionViewCell else { return UICollectionViewCell() }

        if indexPath.row < todoListViewModel.todos.count {
            cell.todoListData = todoListViewModel.todos[indexPath.row]
            return cell
        }
        else{
            guard let addCell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddCell", for: indexPath) as? TodoAddCollectionViewCell else { return TodoAddCollectionViewCell()}
            addCell.profileViewModel = profileViewModel
            return addCell
        }
    }
    
    //Header
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerView", for: indexPath) as? HeaderCollectionReusableView else { return UICollectionReusableView() }
  
            //animation
         
            
            //[TODO]
            let percentage = todoListViewModel.calculatePercentage()
            
            headerView.progressView.setProgress(Float(percentage) / 100, animated: true)
            headerView.progressView.progressTintColor = profileViewModel.color.rgb
            if percentage == 100 {
                setupAnimation()
            }
            headerView.profileImage.makeRounded() //profile radius
            let convertedImage = profileViewModel.profile.last?.profileImg
            if convertedImage != nil {
                headerView.profileImage.image = UIImage(data: convertedImage ?? Data())
            }
            else {
                headerView.profileImage.image = UIImage(systemName: "person.fill")?.withTintColor(.gray, renderingMode: .alwaysOriginal)
            }
            headerView.nickName.text = profileViewModel.profile.last?.nickName
            headerView.uiViewController = self
            headerView.percentage.text = "\(percentage)%"
            headerView.addTaskButton.addTarget(self, action: #selector(showModal), for: .touchUpInside)
            headerView.changeProfileButton.addTarget(self, action: #selector(changeProfile), for: .touchUpInside)
        
            //[question: How to implement the code below?]
//            headerView.addTaskButton = UIButton(type: .system, primaryAction: UIAction(handler: { (_) in
//                self.showModal()
//                self.todoListViewModel.updateMode(.write)
//            }))
            return headerView
        default:
            assert(false, "dd")
        }
        return UICollectionReusableView()
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
  
        if indexPath.row < todoListViewModel.todos.count {
            todoListViewModel.todos[indexPath.row].isDone = !todoListViewModel.todos[indexPath.row].isDone
            todoListViewModel.saveToday()
            collectionView.reloadData()
        }
        else {
            showModal(index: indexPath.row as NSNumber)
        }
    }
}

extension TodoViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let margin: CGFloat = 10
        let itemSpacing: CGFloat = 10
        let width: CGFloat = (collectionView.bounds.width - margin * 2 - itemSpacing)/2
        let height: CGFloat = width
        return CGSize(width: width, height: height)
    }
}
//MARK: action events
extension TodoViewController {
    @objc func showModal(index: NSNumber?){
        let vc = self.storyboard?.instantiateViewController(identifier: "ModalViewController") as! ModalViewController
        vc.modalTransitionStyle = .crossDissolve
        vc.modalViewModel = todoListViewModel
        if todoListViewModel.fetchMode() == .edit{
            vc.todos = todoListViewModel.todos[index as! Int]
        }
        present(vc, animated: true, completion: nil)
    }
    
    func fetchTasks(){
            todoListViewModel.loadTasks()
            profileViewModel.fetchProfile()
            self.collectionView.reloadData()
    }
    
    

    @objc func changeProfile(){
        guard let vc = (self.storyboard?.instantiateViewController(identifier: "EditProfileViewController") as? EditProfileViewController) else { return }
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true, completion: nil)

    }
    func setupAnimation(){
        animationView.frame = view.bounds
        animationView.backgroundColor = .clear
        animationView.animation = Animation.named("32585-fireworks-display")
        animationView.contentMode = .scaleAspectFit
        //animationView.loopMode = .loop
        animationView.isUserInteractionEnabled = false
        animationView.frame = CGRect(x: 50, y: 80, width: 150, height: 150)
        view.addSubview(animationView)
        animationView.play()
    }
    

}
//MARK: Context Menu
//TODO: try to make it somewhere else to reuse it just in case.
extension TodoViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        configureContextMenu(index: indexPath.row)
    }
 
    func configureContextMenu(index: Int) -> UIContextMenuConfiguration{
        if index < todoListViewModel.todos.count {
            let context = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (action) -> UIMenu? in
                let edit = UIAction(title: "Edit", image: UIImage(systemName: "square.and.pencil"), identifier: nil, discoverabilityTitle: nil, state: .off) { (_) in
                    print("edit button clicked")
                    self.todoListViewModel.updateMode(.edit)
                    self.showModal(index: index as NSNumber)
                }
                let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), identifier: nil, discoverabilityTitle: nil,attributes: .destructive, state: .off) { (_) in
                    print("delete button clicked")
                    //TodoManager.shared.deleteTodo(self.items?[index] ?? Todo() )
                    self.todoListViewModel.deleteTodo(self.todoListViewModel.todos[index])
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(self.todoListViewModel.todos[index].detail ?? "")"])
                    self.fetchTasks()
                }
                
                return UIMenu(title: "Options", image: nil, identifier: nil, options: UIMenu.Options.displayInline, children: [edit,delete])
            }
            return context
        }
        else {
            return UIContextMenuConfiguration()
        }
    }
}
