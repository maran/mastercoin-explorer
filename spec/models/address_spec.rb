require 'spec_helper'


describe Address do
   context "Address balance" do
    it "Should have transactions" do
      exodus = FactoryGirl.create(:exodus_transaction)
      address = Address.create(name: exodus.receiving_address)
      tx = FactoryGirl.create(:simple_send)

      address.exodus_transactions.count.should eq(1)
      address.sent_transactions.count.should eq(1)
    end

    it "Should calculate a proper current balance" do
      exodus = FactoryGirl.create(:exodus_transaction)

      address = Address.create(name: exodus.receiving_address)
      address.test_balance.should eq(10)

      simple_send = FactoryGirl.create(:simple_send)
      address.balance.should eq(0)
    end

    it "Should reserved a proper amount when creating a Selling Offer" do
      exodus = FactoryGirl.create(:exodus_transaction)
      address = Address.find_or_create_by(name: exodus.receiving_address)
      address.test_balance.should eq(10)

      selling_offer = FactoryGirl.create(:selling_offer)
      address.reload.reserved_test_balance.to_f.should eq(10)

      address.reload.test_balance.to_f.should eq(0)
    end


    it "Should calculate a proper balance when mixing up transactions" do
      exodus = FactoryGirl.create(:exodus_transaction)
      selling_offer = FactoryGirl.create(:selling_offer )
      purchase_offer = FactoryGirl.create(:purchase_offer, amount: 5)

      address = Address.create(name: exodus.receiving_address)
      address.balance.should eq(0)
      address.sold.count.should eq(1)

      Address.find_by(name: purchase_offer.address).bought.count.should eq(1)
    end
  end
end
