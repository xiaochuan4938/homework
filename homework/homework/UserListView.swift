//
//  UserListView.swift
//  homework
//
//  Created by 姚小川 on 11/1/21.
//

import SwiftUI
import Combine



struct User : Codable{
    let id: UInt
    let userId: UInt
    let title: String
    let body: String
    
    var description: String{
        return String("id: \(id)\n userId: \(userId)\n title: \(title)\n body: \(body)" )
    }
}

//make it observable so we get updated automatically with less glue code
class UserListViewModal: ObservableObject {
    @Published var loading = false
    @Published var errorMsg: String!
    @Published var userList = [User]()
    
    func fetchUserListData(){
        loading = true
        errorMsg = nil
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: urlRequest) {[weak self] data, response, error in
            guard let self = self else {return}
            // add additional 2 sec to show the progress view indicating data being loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.loading.toggle()
                if let data = data,
                   let httpResponse = response as? HTTPURLResponse, (200..<300) ~= httpResponse.statusCode{
                    
                    do{
                        let userList = try JSONDecoder().decode([User].self, from: data)
                        self.userList = userList
                    }catch{
                        self.errorMsg = "Invalid json formated data"
                        
                    }
                }else{
                    if let respError = error{
                        self.errorMsg = respError.localizedDescription
                    }else{
                        self.errorMsg = "Error! Something went wrong, yikes"
                    }
                }
            }
        }.resume()
    }
}




struct UserRowView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var user: User
    
    var body: some View {
        ZStack(alignment: .leading){
            RoundedRectangle(cornerRadius: 4)
                .fill(colorScheme == .light ? Color.white : Color.black)
                .shadow(radius: 2)
                .shadow(color: colorScheme == .light ? Color.black : Color.white, radius: 2, x: 0, y: 2)
            
            VStack(alignment: .leading) {
                
                Text("\(self.user.title)")
                    .foregroundColor(.primary)
                    .font(.title).lineLimit(1)
                    .padding(EdgeInsets(top: 30, leading: 0, bottom:3 , trailing: 0))
                
                Text("\(self.user.body)")
                    .foregroundColor(.secondary)
                    .font(.title2)
                    .padding(.bottom, 20).lineLimit(1).multilineTextAlignment(.leading)
                
            }.padding([.leading,.trailing], 10)
        }
    }
}


struct UserListView: View {
    @ObservedObject var viewModel = UserListViewModal()
    
    var body: some View {
        return NavigationView{
            self.contentView.navigationTitle("Users")
        }.onAppear{
            viewModel.fetchUserListData()
        }.onDisappear() {
            print("onDisappear")
        }
    }
    
    
    private  var contentView: AnyView{
       
        if viewModel.loading {
            //show progress view when loading
            return  AnyView(ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color.red)))
        }
        else if let error = viewModel.errorMsg {
            // show error message (you can turn off WI-FI to produce a error before loading)
            let stack = VStack {
                Text("An Error Occured").font(.title)
                Text(error).font(.callout).multilineTextAlignment(.center).padding(.bottom, 40).padding()
                
                Button {
                    viewModel.fetchUserListData()
                } label: {
                    Text("Retry").bold()
                }
            }
            
            return AnyView(stack)
        }
        else{
            // show user list when loaded successfully
        
            // use ScrollView + LazyVStack to avoid List
            let scrollView = ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(content: {
                    ForEach(0..<viewModel.userList.count, id: \.self) { idx in
                        let user = viewModel.userList[idx]
                        NavigationLink(destination: UserDetailView(user: user) ) {
                            UserRowView(user: user)
                        }
                    }.padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
                })
            }
            return AnyView(scrollView)
        }
    }
}


struct UserDetailView: View {
    var user: User
    
    var body: some View {
        return  ScrollView{
            Text(user.description).lineLimit(nil).multilineTextAlignment(.leading).padding()
        }
       
    }
}

