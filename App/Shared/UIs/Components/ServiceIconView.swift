import SwiftUI
import SmartSubscriptionKit

struct ServiceIconView: View {
    let service: KnownService?
    let name: String
    
    init(subscription: SmartSubscriptionKit.Subscription) {
        self.name = subscription.name
        self.service = ServiceIconRegistry.detectService(name: subscription.name, provider: subscription.providerName)
    }
    
    init(name: String, provider: String? = nil) {
        self.name = name
        self.service = ServiceIconRegistry.detectService(name: name, provider: provider)
    }
    
    var body: some View {
        if let service = service {
            ZStack {
                Circle()
                    .fill(service.brandColor)
                    .shadow(color: service.brandColor.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: service.iconName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 48, height: 48)
        } else {
            ZStack {
                Circle()
                    .fill(Color.appCardBackground)
                    .shadow(color: Color.appShadow, radius: 4, x: 0, y: 2)

                Text(name.prefix(1).uppercased())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.appBrandDeepBlue)
            }
            .frame(width: 48, height: 48)
        }
            }
}
