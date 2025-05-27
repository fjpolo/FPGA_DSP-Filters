class wbpwmaudio_sequence extends uvm_sequence #(wbpwmaudio_transaction);
    `uvm_object_utils(wbpwmaudio_sequence)
    
    function new(string name = "wbpwmaudio_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        wbpwmaudio_transaction trans;
        
        // Apply reset
        trans = wbpwmaudio_transaction::type_id::create("trans");
        trans.reset_n = 0;
        start_item(trans);
        finish_item(trans);
        
        // Release reset and send random data
        repeat(10) begin
            trans = wbpwmaudio_transaction::type_id::create("trans");
            trans.reset_n = 1;
            assert(trans.randomize());
            start_item(trans);
            finish_item(trans);
        end
    endtask
endclass