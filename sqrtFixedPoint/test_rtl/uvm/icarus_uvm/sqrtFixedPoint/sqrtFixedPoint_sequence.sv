class sqrtFixedPoint_sequence extends uvm_sequence #(sqrtFixedPoint_transaction);
    `uvm_object_utils(sqrtFixedPoint_sequence)
    
    function new(string name = "sqrtFixedPoint_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        sqrtFixedPoint_transaction trans;
        
        // Apply reset
        trans = sqrtFixedPoint_transaction::type_id::create("trans");
        trans.reset_n = 0;
        start_item(trans);
        finish_item(trans);
        
        // Release reset and send random data
        repeat(10) begin
            trans = sqrtFixedPoint_transaction::type_id::create("trans");
            trans.reset_n = 1;
            assert(trans.randomize());
            start_item(trans);
            finish_item(trans);
        end
    endtask
endclass