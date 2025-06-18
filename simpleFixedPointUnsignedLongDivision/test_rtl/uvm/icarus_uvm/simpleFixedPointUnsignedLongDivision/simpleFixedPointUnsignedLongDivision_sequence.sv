class simpleFixedPointUnsignedLongDivision_sequence extends uvm_sequence #(simpleFixedPointUnsignedLongDivision_transaction);
    `uvm_object_utils(simpleFixedPointUnsignedLongDivision_sequence)
    
    function new(string name = "simpleFixedPointUnsignedLongDivision_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        simpleFixedPointUnsignedLongDivision_transaction trans;
        
        // Apply reset
        trans = simpleFixedPointUnsignedLongDivision_transaction::type_id::create("trans");
        trans.reset_n = 0;
        start_item(trans);
        finish_item(trans);
        
        // Release reset and send random data
        repeat(10) begin
            trans = simpleFixedPointUnsignedLongDivision_transaction::type_id::create("trans");
            trans.reset_n = 1;
            assert(trans.randomize());
            start_item(trans);
            finish_item(trans);
        end
    endtask
endclass