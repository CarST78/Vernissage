//
//  https://mczachurski.dev
//  Copyright © 2022 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
    

import Foundation

class AccountDataHandler {
    func getAccountsData() -> [AccountData] {
        let context = CoreDataHandler.shared.container.viewContext
        let fetchRequest = AccountData.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error during fetching accounts")
            return []
        }
    }
    
    func getCurrentAccountData() -> AccountData? {
        let accounts = self.getAccountsData()
        
        let applicationSettingsHandler = ApplicationSettingsHandler()
        let defaultSettings = applicationSettingsHandler.getDefaultSettings()
        
        let currentAccount = accounts.first { accountData in
            accountData.id == defaultSettings.currentAccount
        }
        
        if let currentAccount {
            return currentAccount
        }
        
        return accounts.first
    }

    func createAccountDataEntity() -> AccountData {
        let context = CoreDataHandler.shared.container.viewContext
        return AccountData(context: context)
    }
}
