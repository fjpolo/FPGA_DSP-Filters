class simpleFixedPointLongDivision_sequence extends uvm_sequence #(simpleFixedPointLongDivision_transaction);
    `uvm_object_utils(simpleFixedPointLongDivision_sequence)
    
    function new(string name = "simpleFixedPointLongDivision_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        simpleFixedPointLongDivision_transaction trans;
        
        // Apply reset
        trans = simpleFixedPointLongDivision_transaction::type_id::create("trans");
        trans.reset_n = 0;
        start_item(trans);
        finish_item(trans);
        
        // Release reset and send random data
        repeat(10) begin
            trans = simpleFixedPointLongDivision_transaction::type_id::create("trans");
            trans.reset_n = 1;
            assert(trans.randomize());
            start_item(trans);
            finish_item(trans);
        end
    endtask
endclass