describe "Application 'multi_timer'" do
  before do
    @app = UIApplication.sharedApplication
  end

  it "has one window" do
    # TODO: Deal with this spec!
    @app.windows.size.should == 0
  end
end
