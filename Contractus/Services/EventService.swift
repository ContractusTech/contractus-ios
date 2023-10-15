//
//  EventService.swift
//  Contractus
//
//  Created by VITALIY FADEYEV on 12.08.2023.
//

import Foundation
import ContractusAPI
import Firebase

public enum ContractorType: String {
    case client, executor, checker
}

protocol AnalyticsEvent {
    var name: String { get }
    var params: [String: Any] { get }
}

enum DefaultAnalyticsEvent: String {
    case startApp = "start_app"                                             /// Запуск приложения
    case startNewAccountTap = "start_new_account_tap"                       /// Нажатие на New Account
    case startImportAccountTap = "start_import_account_tap"                 /// Нажатие на Import Account
    case startBackupTap = "start_backup_tap"                                /// Нажатие на экране Бэкапа
    case mainOpen = "main_open"                                             /// Открыт клавный экран
    case mainTopupTap = "main_topup_tap"                                    /// Нажатие на TopUp
    case mainTiersTap = "main_tiers_tap"                                    /// Нажатие на хедер вверху, что бы посмотреть информацию о тарифе
    case mainNewDealTap = "main_new_deal_tap"                               /// Нажатие на кнопку "New Deal"
    case mainAccountAddressTap = "main_account_address_tap"                 /// Нажатие на кнопку QR кода твоего акканта
    case mainQRscannerTap = "main_qrscanner_tap"                            /// Нажатие на кнопку сканнера
    case mainDealTap = "main_deal_tap"                                      /// Нажатие на сделку
    case mainSettingsTap = "main_settings_tap"                              /// Нажатие на кнопку Настроек
    case newDealOpen = "new_deal_open"                                      /// Открытие страницы "Создания сделки"
    case newDealCreateTap = "new_deal_create_tap"                           /// Нажатие на "Создать сделку"
    case newDealOpenSuccessWithSk = "new_deal_open_success_with_sk"         /// Открытие экрана с секретным ключем после создания сделки
    case dealOpen = "deal_open"                                             /// Открытие страницы сделки
    case dealChangeAmountTap = "deal_change_amount_tap"                     /// Открытие экрана изменения стоимости сделки
    case dealChangeAmountUpdateTap = "deal_change_amount_update_tap"        /// Нажатие кнопки на сохранение новой цены
    case dealDescriptionAddFileTap = "deal_description_add_file_tap"        /// Нажатие на добавление файла
    case dealDescriptionTap = "deal_description_tap"                        /// Нажатие на кнопку изменение описания сделки
    case dealDescriptionSaveTap = "deal_description_save_tap"               /// Сохранение описание сделки
    case dealResultTap = "deal_result_tap"                                  /// Нажатие на изменения текста результата сделки
    case dealResultSaveTap = "deal_result_save_tap"                         /// Сохранение описание результата сделки
    case dealResultAddFileTap = "deal_result_add_file_tap"                  /// Нажатие на добавление файла в результат сделки
    case dealRevokeTap = "deal_revoke_tap"                                  /// Нажатие на отмену (именно revoke) сделки
    case dealSignTap = "deal_sign_tap"                                      /// Нажатие на подпись сделки
    case dealContractorTap = "deal_contractor_tap"                          /// Нажатие на редатирования исполнителя
    case dealContractorUpdateTap = "deal_contractor_update_tap"             /// Нажатие на кнопку обновление клиента, сохранения
    case dealContractorQrscannerTap = "deal_contractor_qrscanner_tap"       /// Нажатие на сканнер QR
    case txOpen = "tx_open"                                                 /// Открытие экрана подписи транзакции
    case txSignTap = "tx_sign_tap"                                          /// Нажатие на "Sign" на экране транзакции
    case txSignatureTap = "tx_signature_tap"                                /// Нажатие на просмотр транзакции по signature
    case txDataCopyTap = "tx_data_copy_tap"                                 /// Нажатие на кнопку в транзакции Copy
    case txDataViewTap = "tx_data_view_tap"                                 /// Нажатие на кнопку раскрытия транзакции (стрелка вверх/вниз)
    case settingsOpen = "settings_open"                                     /// Открытие настроек
    case settingsAccountsTap = "settings_accounts_tap"                      /// Нажатие на список аккаунтов
    case settingsFaqTap = "settings_faq_tap"                                /// Нажатие на FAQ
    case accountsOpen = "accounts_open"                                     /// Открытие экрана списка аккаунта
    case accountsSelectTap = "accounts_select_tap"                          /// Нажатие на галку выбора аккаунта
    case accountsAddTap = "accounts_add_tap"                                /// Нажатие на добавить аккаунт
    case accountsEditTap = "accounts_edit_tap"                              /// Нажатие на редактирования списка
    case accountsRemoveTap = "accounts_remove_tap"                          /// Нажатие на редактирования списка
    case accountsBackupTap = "accounts_backup_tap"                          /// Нажатие на бэкап
    case backupAccountTap = "backup_account_tap"                            /// На экране бэкапа при смене настройки бэкапа
    case deleteAccountTap = "delete_account_tap"                            /// Подтвержить удаление на экране удаления аккаунта надатие
    case referralOpen = "referral_open"                                     /// Открытие реферальной программы
    case referralCodeCopyTap = "referral_code_copy_tap"                     /// Копирование промокода
    case referralCodeCreateTap = "referral_code_create_tap"                 /// Создание промокода
    case referralApplyCodeFormTap = "referral_apply_code_form_tap"          /// Нажатие на кнопку открытие формы ввода
    case referralApplyCodeTap = "referral_apply_code_tap"                   /// Нажатие на "Применить код" на форме ввода
    case referralApplyCodeSuccess = "referral_apply_code_success"           /// Если успешно применен код
    case referralApplyCodeError = "referral_apply_code_error"               /// Ошибка при отправке кода
    case onboardingOpen = "onboarding_open"                                 /// Открыие онбординга
    case onboardingСlose = "onboarding_close"                               /// Закрытие онбординга
    case changelogOpen = "changelog_open"                                   /// Открыие лога изменений
    case changelogСlose = "changelog_close"                                 /// Закрытие лога изменений
    case buyformOpen = "buyform_open"                                       /// Открытие формы покупки токенов
    case buyformBuyTap = "buyform_buy_tap"                                  /// Нажатие на кнопку покупки
}

extension DefaultAnalyticsEvent: AnalyticsEvent {
    var name: String { self.rawValue }
    var params: [String : Any] { [:] }
}

enum ExtendedAnalyticsEvent {
    case startBackupTap(Bool),
         mainTiersTap(Balance.Tier),
         newDealCreateTap(OwnerRole, Bool, PerformanceBondType, Bool),
         dealChangeAmountUpdateTap(Bool),
         dealContractorTap(ContractorType),
         dealContractorUpdateTap(ContractorType),
         backupAccountTap(Bool),
         deleteAccountTap(Bool),
         referralApplyCodeError(String),
         changelogOpen(Int),
         changelogClose(Int)
}

extension ExtendedAnalyticsEvent: AnalyticsEvent {
    var name: String {
        switch self {
        case .startBackupTap(_):
            return DefaultAnalyticsEvent.startBackupTap.rawValue
        case .mainTiersTap(_):
            return DefaultAnalyticsEvent.mainTiersTap.rawValue
        case .newDealCreateTap(_, _, _, _):
            return DefaultAnalyticsEvent.newDealCreateTap.rawValue
        case .dealChangeAmountUpdateTap(_):
            return DefaultAnalyticsEvent.dealChangeAmountUpdateTap.rawValue
        case .dealContractorTap(_):
            return DefaultAnalyticsEvent.dealContractorTap.rawValue
        case .dealContractorUpdateTap(_):
            return DefaultAnalyticsEvent.dealContractorUpdateTap.rawValue
        case .backupAccountTap(_):
            return DefaultAnalyticsEvent.backupAccountTap.rawValue
        case .deleteAccountTap(_):
            return DefaultAnalyticsEvent.deleteAccountTap.rawValue
        case .referralApplyCodeError(_):
            return DefaultAnalyticsEvent.referralApplyCodeError.rawValue
        case .changelogOpen(_):
            return DefaultAnalyticsEvent.changelogOpen.rawValue
        case .changelogClose(_):
            return DefaultAnalyticsEvent.changelogСlose.rawValue
        }
    }
    
    var params: [String : Any] {
        switch self {
        case .startBackupTap(let param):
            return ["backup": param]
        case .mainTiersTap(let tier):
            return ["tier": tier.rawValue]
        case .newDealCreateTap(let role, let thirdParty, let bondType, let secretKey):
            return ["role": role, "third_party": thirdParty, "bond_type": bondType, "secret_key": secretKey]
        case .dealChangeAmountUpdateTap(let holderMode):
            return ["holder_mode": holderMode]
        case .dealContractorTap(let type):
            return ["type": type.rawValue]
        case .dealContractorUpdateTap(let type):
            return ["type": type.rawValue]
        case .backupAccountTap(let allow):
            return ["allow": allow]
        case .deleteAccountTap(let deleteBackup):
            return ["delete_backup": deleteBackup]
        case .referralApplyCodeError(let message):
            return ["message": message]
        case .changelogOpen(let id):
            return ["id": id]
        case .changelogClose(let id):
            return ["id": id]
        }
    }
}

final class EventService {

    // MARK: - Shared
    static let shared = EventService()

    func send(event: AnalyticsEvent) {
        debugPrint("FIR: Name: \(event.name), Params: \(event.params)")
        Analytics.logEvent(event.name, parameters: event.params)
    }
}
