class FixedPointAdder_sequence extends uvm_sequence #(FixedPointAdder_transaction);
    `uvm_object_utils(FixedPointAdder_sequence)
    
    function new(string name = "FixedPointAdder_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        FixedPointAdder_transaction trans;
        
        // Apply reset
        trans = FixedPointAdder_transaction::type_id::create("trans");
        trans.reset_n = 0;
        start_item(trans);
        finish_item(trans);
        
        // Release reset and send random data
        repeat(10) begin
            trans = FixedPointAdder_transaction::type_id::create("trans");
            trans.reset_n = 1;
            assert(trans.randomize());
            start_item(trans);
            finish_item(trans);
        end
    endtask
endclass