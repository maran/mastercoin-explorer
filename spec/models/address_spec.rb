require 'spec_helper'


describe Address do
  context "Address balance" do
    it "Should calculate a proper current balance" do
      exodus = FactoryGirl.create(:exodus_transaction)

      address = Address.new(exodus.receiving_address)
      address.balance.should eq(10)

      simple_send = FactoryGirl.create(:simple_send)
      address.balance.should eq(0)

    end

    it "Should calculate a proper balance when looking back in time" do
      exodus = FactoryGirl.create(:exodus_transaction)
      simple_send = FactoryGirl.create(:simple_send)

      address = Address.new(exodus.receiving_address)
      address.balance(1, before_app_position: simple_send.app_position).to_f.should eq(10.0)
    end

    it "Should calculate a proper balance when mixing up transactions" do
      exodus = FactoryGirl.create(:exodus_transaction)
      selling_offer = FactoryGirl.create(:selling_offer )
      purchase_offer = FactoryGirl.create(:purchase_offer)

      address = Address.new(exodus.receiving_address)
      address.balance.should eq(10)
    end
  end
end
