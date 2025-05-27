class pwmaudio_sequence extends uvm_sequence #(pwmaudio_transaction);
    `uvm_object_utils(pwmaudio_sequence)
    
    function new(string name = "pwmaudio_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        pwmaudio_transaction trans;
        
        // Apply reset
        trans = pwmaudio_transaction::type_id::create("trans");
        trans.reset_n = 0;
        start_item(trans);
        finish_item(trans);
        
        // Release reset and send random data
        repeat(10) begin
            trans = pwmaudio_transaction::type_id::create("trans");
            trans.reset_n = 1;
            assert(trans.randomize());
            start_item(trans);
            finish_item(trans);
        end
    endtask
endclass