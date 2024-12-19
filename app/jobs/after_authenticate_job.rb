class AfterAuthenticateJob < ApplicationJob
  queue_as :default

  def perform(shop_domain:)
    shop = Shop.find_by!(shopify_domain: shop_domain)

    # Perform any important work after app install/re-install
    #
    # Example use cases are:
    # 1. Syncing shop model with Shopify before app usage
    # 2. Syncing metafields
    # 3. Syncing products
    # 4. Fetching storefront credentials
    # 5. etc.
  end
end
