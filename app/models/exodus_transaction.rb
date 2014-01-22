class ExodusTransaction < Transaction
  after_create :revalidate_children
end
